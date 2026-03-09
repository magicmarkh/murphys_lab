#!/bin/bash
# =====================================================================
# Ordered Destroy Script for Windows Target with Domain Unjoin
# =====================================================================
# This script ensures proper teardown order:
# 1. Unjoin from domain (while instance is still running)
# 2. Destroy all resources
#
# Usage: ./destroy_ordered.sh [terraform destroy options]
# Example: ./destroy_ordered.sh -auto-approve
# =====================================================================

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}==================== ORDERED DESTROY PROCESS ====================${NC}"
echo "This script will:"
echo "  1. Unjoin the instance from the domain (while still running)"
echo "  2. Destroy all Terraform resources"
echo ""

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
  echo -e "${RED}Error: Terraform not initialized. Run 'terraform init' first.${NC}"
  exit 1
fi

# Step 1: Unjoin from domain
echo -e "${YELLOW}Step 1: Unjoining instance from domain...${NC}"
if terraform destroy -target=terraform_data.domain_operations "$@"; then
  echo -e "${GREEN}✓ Domain unjoin successful${NC}"
else
  echo -e "${RED}✗ Domain unjoin failed!${NC}"
  echo ""
  echo "Options:"
  echo "  1. Fix the connectivity issue and re-run this script"
  echo "  2. Manually unjoin the instance from Active Directory"
  echo "  3. Continue with destroy (instance will remain in AD)"
  echo ""
  read -p "Continue with full destroy anyway? (yes/no): " CONTINUE
  if [ "$CONTINUE" != "yes" ]; then
    echo "Aborting. Run this script again when ready."
    exit 1
  fi
  echo -e "${YELLOW}Continuing with destroy (instance will remain in AD)...${NC}"
fi

echo ""
echo -e "${YELLOW}Step 2: Destroying all resources...${NC}"

# Step 2: Destroy everything
if terraform destroy "$@"; then
  echo ""
  echo -e "${GREEN}==================== DESTROY COMPLETE ====================${NC}"
  exit 0
else
  echo ""
  echo -e "${RED}==================== DESTROY FAILED ====================${NC}"
  exit 1
fi
