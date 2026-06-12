#!/bin/bash
# Patches the cached cyberark/cce-organization/aws module after terraform init.
#
# Historical note: Earlier versions of this module did not declare
# required_providers for idsec, so Terraform defaulted to hashicorp/idsec
# instead of cyberark/idsec. Module v0.2.2+ now declares the correct source,
# so this script only verifies the provider source is correct.
#
# Usage: Run after every 'terraform init'
#   terraform init && ./patch_module.sh
set -euo pipefail

MODULE_CACHE=".terraform/modules/cce_aws_organization"

if [[ ! -d "$MODULE_CACHE" ]]; then
  echo "Module cache not found at ${MODULE_CACHE}. Run 'terraform init' first."
  exit 1
fi

# Verify the module declares the correct idsec provider source
if grep -q '"cyberark/idsec"' "${MODULE_CACHE}/main.tf" 2>/dev/null; then
  echo "OK: Module already declares cyberark/idsec provider source."
else
  echo "WARNING: Module does not declare cyberark/idsec. You may need to patch manually."
  echo "  Check ${MODULE_CACHE}/main.tf for the required_providers block."
  exit 1
fi
