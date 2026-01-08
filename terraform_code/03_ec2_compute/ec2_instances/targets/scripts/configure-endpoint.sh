#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LOG=/var/log/sia_configure.log
FLAG=/var/log/sia_configure_done
echo "running" >&2
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
: "${WORKSPACE_ID:?WORKSPACE_ID is required}"
: "${WORKSPACE_TYPE:?WORKSPACE_TYPE is required}"

# ── Idempotency guard ────────────────────────────────────────────────────────
if [[ -f "$FLAG" ]]; then
  echo "[register] Registration already completed; skipping." | tee -a "$LOG"
  exit 0
fi

{
  echo "[$(date)] [register] Starting target configuration"

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

  # 3) Get Configure Script & Configure the target system
  CONFIGURE_TARGET_API_URL="https://${PLATFORM_TENANT_NAME}.dpa.cyberark.cloud/api/public-keys/scripts"
  echo "[$(date)] [register] Requesting setup script from ${CONFIGURE_TARGET_API_URL}"
  setup_resp=$(curl -sk -X GET "$CONFIGURE_TARGET_API_URL" \
    -H "Authorization: Bearer ${platform_token}" \
    -H "Content-Type: application/json" \
    -d "workspaceId=${WORKSPACE_ID}" \
    -d "workspaceType=${WORKSPACE_TYPE}"
  )

  # Decode the Base64 payload into bash_cmd
  base64_payload=$(jq -r '.base64_cmd' <<<"$setup_resp")
  if [[ -z "$base64_payload" || "$base64_payload" == "null" ]]; then
    echo "[$(date)] [register] ERROR: No 'base64_cmd' returned in setup response" >&2
    exit 3
  fi

  bash_cmd=$(echo "$base64_payload" | base64 --decode)
  echo "[$(date)] [register] Executing decoded setup script"
  eval "$bash_cmd"

  # 5) Invalidate token
  echo "[$(date)] [register] Logging out"
  curl -sk -X POST "${IDENTITY_URL}/security/logout" \
       -H "Authorization: Bearer ${platform_token}" || true

  echo "[$(date)] [register] Connector registration completed successfully"
} 2>&1 | tee -a "$LOG"

# Mark done
touch "$FLAG"

#script cleanup
rm -rf /opt/sia
