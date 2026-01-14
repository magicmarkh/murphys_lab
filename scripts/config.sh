#!/bin/bash
# Shared configuration for tfvars and backend.tf management scripts

# S3 Configuration
export TFVARS_S3_BUCKET="us-ent-east"
export TFVARS_S3_REGION="us-east-2"
export TFVARS_S3_PREFIX="tfvars-config"

# Repository root (auto-detected)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# File patterns to manage
export TFVARS_FILENAME="terraform.tfvars"
export BACKEND_FILENAME="backend.tf"

# Sensitive field patterns
SENSITIVE_FIELDS=("conjur_login" "conjur_api_key")

# SSH Key Configuration
SSH_KEY_PATH="terraform_code/03_ec2_compute/key_pair"
SSH_KEY_FILENAME="us-ent-east-key.pem"
export SSH_KEY_PATH SSH_KEY_FILENAME

# Terraform code directories to process
TERRAFORM_CODE_DIRS=(
    "01_foundation"
    "02_security"
    "03_ec2_compute"
    "04_rds_databases"
    "05_cyberark_config/connector_pools"
    "05_cyberark_config/users"
    "05_cyberark_config/accounts/database"
    "05_cyberark_config/accounts/linux"
    "05_cyberark_config/accounts/windows"
    "05_cyberark_config/accounts/cloud"
)

# Example directories to process
EXAMPLE_DIRS=(
    "privilege_cloud"
    "identity"
    "access_policy/csp_console/aws_iam"
    "access_policy/csp_console/aws_idc"
    "access_policy/csp_console/azure"
    "access_policy/csp_console/entra"
    "access_policy/csp_console/gcp"
)

# Colors for output (optional, for better UX)
export COLOR_GREEN='\033[0;32m'
export COLOR_RED='\033[0;31m'
export COLOR_YELLOW='\033[1;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_RESET='\033[0m'
