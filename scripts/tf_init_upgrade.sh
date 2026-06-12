#!/bin/bash
# =============================================================================
# Terraform Init Upgrade - Runs 'terraform init -upgrade' across all layers
#
# Upgrades provider versions (within version constraints) for every Terraform
# root module in the repo. Useful after updating provider version pins.
#
# Usage:
#   ./scripts/tf_init_upgrade.sh            # upgrade all layers
#   ./scripts/tf_init_upgrade.sh 99_demo    # upgrade only layers matching pattern
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

FILTER="${1:-}"

# Also include sia_settings which is missing from TERRAFORM_CODE_DIRS in config.sh
ALL_DIRS=(
    "${TERRAFORM_CODE_DIRS[@]}"
    "05_cyberark_config/sia_settings"
)

# De-duplicate and sort (compatible with macOS bash 3.2)
ALL_DIRS_SORTED=()
while IFS= read -r line; do
    ALL_DIRS_SORTED+=("$line")
done < <(printf '%s\n' "${ALL_DIRS[@]}" | sort -u)
ALL_DIRS=("${ALL_DIRS_SORTED[@]}")

PASS=0
FAIL=0
SKIP=0

echo ""
echo "============================================="
echo "  Terraform Init Upgrade"
echo "============================================="
echo ""

for dir in "${ALL_DIRS[@]}"; do
    full_path="${REPO_ROOT}/terraform_code/${dir}"

    # Apply filter if provided
    if [[ -n "$FILTER" ]] && [[ "$dir" != *"$FILTER"* ]]; then
        SKIP=$((SKIP + 1))
        continue
    fi

    if [[ ! -d "$full_path" ]]; then
        printf "${COLOR_YELLOW}SKIP${COLOR_RESET}  %s (directory not found)\n" "$dir"
        SKIP=$((SKIP + 1))
        continue
    fi

    printf "${COLOR_BLUE}INIT${COLOR_RESET}  %s ... " "$dir"

    if CONJURRC=/dev/null terraform -chdir="$full_path" init -upgrade -input=false > /tmp/tf_init_output_$$ 2>&1; then
        printf "${COLOR_GREEN}OK${COLOR_RESET}\n"
        PASS=$((PASS + 1))
    else
        printf "${COLOR_RED}FAILED${COLOR_RESET}\n"
        # Show last 5 lines of error output
        tail -5 /tmp/tf_init_output_$$ | sed 's/^/       /'
        FAIL=$((FAIL + 1))
    fi

    rm -f /tmp/tf_init_output_$$
done

echo ""
echo "============================================="
printf "  Results: ${COLOR_GREEN}%d passed${COLOR_RESET}" "$PASS"
if [[ $FAIL -gt 0 ]]; then
    printf ", ${COLOR_RED}%d failed${COLOR_RESET}" "$FAIL"
fi
if [[ $SKIP -gt 0 ]]; then
    printf ", ${COLOR_YELLOW}%d skipped${COLOR_RESET}" "$SKIP"
fi
echo ""
echo "============================================="
echo ""

exit $FAIL
