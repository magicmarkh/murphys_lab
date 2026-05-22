#!/bin/bash
# Patches the cached cyberark/cce-organization/aws module after terraform init.
#
# The module does not declare required_providers for idsec, so Terraform
# defaults to hashicorp/idsec instead of cyberark/idsec. This script
# creates the missing versions.tf in the cached module directory.
#
# Usage: Run after every 'terraform init'
#   terraform init && ./patch_module.sh
set -euo pipefail

MODULE_CACHE=".terraform/modules/cce_aws_organization"
VERSIONS_FILE="${MODULE_CACHE}/versions.tf"

if [[ ! -d "$MODULE_CACHE" ]]; then
  echo "Module cache not found at ${MODULE_CACHE}. Run 'terraform init' first."
  exit 1
fi

if [[ -f "$VERSIONS_FILE" ]]; then
  echo "versions.tf already exists in ${MODULE_CACHE} -- no patch needed."
  exit 0
fi

cat > "$VERSIONS_FILE" << 'EOF'
terraform {
  required_version = ">= 1.8.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = ">= 0.3.3"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
    terraform = {
      source = "terraform.io/builtin/terraform"
    }
  }
}
EOF

echo "Patched: created ${VERSIONS_FILE} with cyberark/idsec provider source."
