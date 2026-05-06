#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

LOG=/var/log/sia_configure.log
FLAG=/var/log/sia_configure_done
echo "running" >&2
# ── Ensure we're running as root ───────────────────────────────────────────────
if (( EUID != 0 )); then
  echo "[register] ERROR: Must be run as root" >&2
  exit 1
fi

# ── Install required tools ────────────────────────────────────────────────────
echo "[install] Installing git, terraform, ansible, and nano"

# Detect OS
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS=$ID
else
  echo "[install] ERROR: Cannot detect OS" >&2
  exit 1
fi

# Install git
echo "[install] Installing git..."
case $OS in
  ubuntu|debian)
    apt-get update -y
    apt-get install -y git software-properties-common gnupg curl
    ;;
  amzn)
    dnf install -y git
    ;;
  centos|rhel|fedora)
    yum install -y git
    ;;
  *)
    echo "[install] WARNING: Unsupported OS for git installation: $OS"
    ;;
esac

# Install nano
echo "[install] Installing nano..."
case $OS in
  ubuntu|debian)
    apt-get install -y nano
    ;;
  amzn)
    dnf install -y nano
    ;;
  centos|rhel|fedora)
    yum install -y nano
    ;;
  *)
    echo "[install] WARNING: Unsupported OS for nano installation: $OS"
    ;;
esac

# Install Terraform
echo "[install] Installing terraform..."
TERRAFORM_VERSION="1.8.5"
if ! command -v terraform >/dev/null 2>&1; then
  case $OS in
    ubuntu|debian)
      curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
      apt-get update -y
      apt-get install -y terraform
      ;;
    amzn)
      dnf install -y dnf-plugins-core
      dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
      dnf install -y terraform
      ;;
    centos|rhel|fedora)
      yum install -y yum-utils
      yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
      yum install -y terraform
      ;;
    *)
      # Fallback: download binary directly
      wget -O /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
      unzip -o /tmp/terraform.zip -d /usr/local/bin/
      chmod +x /usr/local/bin/terraform
      rm /tmp/terraform.zip
      ;;
  esac
else
  echo "[install] Terraform already installed"
fi

# Install Ansible
echo "[install] Installing ansible..."
case $OS in
  ubuntu|debian)
    apt-get update -y
    apt-get install -y ansible
    ;;
  amzn)
    dnf install -y ansible
    ;;
  centos|rhel|fedora)
    yum install -y ansible
    ;;
  *)
    echo "[install] WARNING: Unsupported OS for ansible installation: $OS"
    ;;
esac

# Install python3-pip and pywinrm for Ansible WinRM support
echo "[install] Installing python3-pip and pywinrm..."
case $OS in
  ubuntu|debian)
    apt-get install -y python3-pip
    ;;
  amzn)
    dnf install -y python3-pip
    ;;
  centos|rhel|fedora)
    yum install -y python3-pip
    ;;
  *)
    echo "[install] WARNING: Unsupported OS for pip installation: $OS"
    ;;
esac
pip3 install pywinrm

echo "[install] Installation complete"

# ── Check for required tools ──────────────────────────────────────────────────
for cmd in jq curl git nano terraform ansible; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[register] ERROR: '$cmd' not installed" >&2
    exit 1
  fi
done

# ── Validate required environment variables ──────────────────────────────────
: "${IDENTITY_CLIENT_ID:?IDENTITY_CLIENT_ID is required}"
: "${IDENTITY_CLIENT_SECRET:?IDENTITY_CLIENT_SECRET is required}"
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

  # 1) Use CyberArk platform credentials from environment
  echo "[$(date)] [register] Using platform credentials from environment"
  client_id="$IDENTITY_CLIENT_ID"
  client_secret="$IDENTITY_CLIENT_SECRET"

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

  echo "[$(date)] [register]Target registration completed successfully"
} 2>&1 | tee -a "$LOG"

# Mark done
touch "$FLAG"

#script cleanup
rm -rf /opt/sia
