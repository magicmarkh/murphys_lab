#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LOG=/var/log/sia_register.log
FLAG=/var/log/sia_register_done

# ── Ensure we’re running as root ───────────────────────────────────────────────
if (( EUID != 0 )); then
  echo "[register] ERROR: Must be run as root" >&2
  exit 1
fi

# ── Check for required tools ──────────────────────────────────────────────────
for cmd in aws jq curl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[register] ERROR: '$cmd' not installed" >&2
    exit 1
  fi
done

# ── Validate required environment variables ──────────────────────────────────
: "${AWS_REGION:?AWS_REGION is required}"
: "${PLATFORM_SECRET_ARN:?PLATFORM_SECRET_ARN is required}"
: "${IDENTITY_TENANT_ID:?IDENTITY_TENANT_ID is required}"
: "${PLATFORM_TENANT_NAME:?PLATFORM_TENANT_NAME is required}"
: "${CONNECTOR_POOL_NAME:?CONNECTOR_POOL_NAME is required}"

# ── Idempotency guard ────────────────────────────────────────────────────────
if [[ -f "$FLAG" ]]; then
  echo "[register] Registration already completed; skipping." | tee -a "$LOG"
  exit 0
fi

{
  echo "[$(date)] [register] Starting connector registration"

  # 1) Fetch CyberArk platform credentials
  echo "[$(date)] [register] Fetching platform creds from Secrets Manager"
  secret_json=$(aws secretsmanager get-secret-value \
    --region "$AWS_REGION" \
    --secret-id "$PLATFORM_SECRET_ARN" \
    --query SecretString --output text)

  client_id=$(jq -r '.username' <<<"$secret_json")
  client_secret=$(jq -r '.password' <<<"$secret_json")

  # 2) Obtain OAuth token 
  IDENTITY_URL="https://${IDENTITY_TENANT_ID}.id.cyberark.cloud"
  PLATFORM_TOKEN_URL="${IDENTITY_URL}/oauth2/platformtoken"

  echo "[$(date)] [register] Requesting OAuth token (multipart/form-data)"
  resp=$(curl -sk -w "\n%{http_code}" \
    -X POST "$PLATFORM_TOKEN_URL" \
    -H "Accept: application/json" \
    -F "grant_type=client_credentials" \
    -F "client_id=${client_id}" \
    -F "client_secret=${client_secret}")

  http_code=$(tail -n1 <<<"$resp")
  body=$(sed '$d' <<<"$resp")

  echo "[$(date)] [register] HTTP status: $http_code"
  echo "[$(date)] [register] Response body: $body"

  platform_token=$(jq -r '.access_token // empty' <<<"$body")
  echo "[$(date)] [register] Parsed access_token: $platform_token"

  if [[ -z "$platform_token" ]]; then
    echo "[$(date)] [register] ERROR: Failed to obtain platform token" >&2
    exit 1
  fi

  # 3) Lookup connector‐pool ID
  CM_DOMAIN="${PLATFORM_TENANT_NAME}.connectormanagement.cyberark.cloud"
  echo "[$(date)] [register] Fetching connector pools from ${CM_DOMAIN}"
  pools=$(curl -sk -H "Authorization: Bearer ${platform_token}" \
    "https://${CM_DOMAIN}/api/connector-pools")

  pool_id=$(jq -r ".connectorPools[] | select(.name==\"${CONNECTOR_POOL_NAME}\") | .poolId" <<<"$pools")
  if [[ -z "$pool_id" || "$pool_id" == "null" ]]; then
    echo "[$(date)] [register] ERROR: Connector pool '${CONNECTOR_POOL_NAME}' not found" >&2
    exit 2
  fi
  echo "[$(date)] [register] Found pool ID: ${pool_id}"

  # 4) JIT setup
  JIT_API_URL="https://${PLATFORM_TENANT_NAME}-jit.cyberark.cloud/api/connectors/setup-script"
  echo "[$(date)] [register] Requesting setup script from ${JIT_API_URL}"
  setup_resp=$(curl -sk -X POST "$JIT_API_URL" \
    -H "Authorization: Bearer ${platform_token}" \
    -H "Content-Type: application/json" \
    -d "{\"connector_type\":\"AWS\",\"connector_os\":\"linux\",\"connector_pool_id\":\"${pool_id}\",\"expiration_minutes\":15}")

  bash_cmd=$(jq -r '.bash_cmd' <<<"$setup_resp")
  if [[ -z "$bash_cmd" || "$bash_cmd" == "null" ]]; then
    echo "[$(date)] [register] ERROR: No 'bash_cmd' returned in setup response" >&2
    exit 3
  fi

  echo "[$(date)] [register] Executing setup script"
  eval "$bash_cmd"

  # 5) Invalidate token
  echo "[$(date)] [register] Logging out"
  curl -sk -X POST "${IDENTITY_URL}/security/logout" \
       -H "Authorization: Bearer ${platform_token}" || true

  echo "[$(date)] [register] Connector registration completed successfully"
} 2>&1 | tee -a "$LOG"

# Mark done
touch "$FLAG"
