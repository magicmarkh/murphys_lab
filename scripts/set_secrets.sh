#!/bin/bash
set -euo pipefail

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Counters for summary
TOTAL_UPDATED=0
TOTAL_SKIPPED=0

# Function: Read secret with no echo
read_secret() {
    local prompt="$1"
    local secret_value

    read -sp "${prompt}: " secret_value
    echo "" >&2  # Output newline to stderr, not stdout
    echo "${secret_value}"
}

# Function: Update a single field in a tfvars file
update_field() {
    local file_path="$1"
    local field_name="$2"
    local field_value="$3"

    if grep -qE "^${field_name}[[:space:]]*=" "${file_path}"; then
        sed -i.bak -E "s|^(${field_name}[[:space:]]*=[[:space:]]*).*|\1\"${field_value}\"|" "${file_path}"
        rm -f "${file_path}.bak"
    fi
}

# Function: Update tfvars file with auth config
update_tfvars_auth() {
    local file_path="$1"
    local authn_type="$2"
    local conjur_login="$3"
    local conjur_api_key="$4"
    local conjur_service_id="$5"
    local conjur_host_id="$6"

    # Check if file has the authn_type field (new-style) or login/api_key fields
    if grep -qE '^conjur_authn_type[[:space:]]*=' "${file_path}" || \
       grep -qE '^conjur_login[[:space:]]*=' "${file_path}" || \
       grep -qE '^conjur_api_key[[:space:]]*=' "${file_path}"; then

        update_field "${file_path}" "conjur_authn_type" "${authn_type}"
        update_field "${file_path}" "conjur_login" "${conjur_login}"
        update_field "${file_path}" "conjur_api_key" "${conjur_api_key}"
        update_field "${file_path}" "conjur_service_id" "${conjur_service_id}"
        update_field "${file_path}" "conjur_host_id" "${conjur_host_id}"

        echo "  ✓ Updated: ${file_path}"
        ((TOTAL_UPDATED++))
        return 0
    else
        echo "  ⊘ No Conjur auth fields found: ${file_path}"
        ((TOTAL_SKIPPED++))
        return 1
    fi
}

# Function: Process terraform_code directories
process_terraform_code() {
    local authn_type="$1"
    local conjur_login="$2"
    local conjur_api_key="$3"
    local conjur_service_id="$4"
    local conjur_host_id="$5"

    echo ""
    echo "Processing terraform_code directories..."
    echo "========================================"

    for dir in "${TERRAFORM_CODE_DIRS[@]}"; do
        local tfvars_path="${REPO_ROOT}/terraform_code/${dir}/${TFVARS_FILENAME}"

        if [[ -f "${tfvars_path}" ]]; then
            echo ""
            echo "Module: terraform_code/${dir}"
            update_tfvars_auth "${tfvars_path}" "${authn_type}" "${conjur_login}" \
                "${conjur_api_key}" "${conjur_service_id}" "${conjur_host_id}" || true
        fi
    done
}

# Function: Process examples directories
process_examples() {
    local authn_type="$1"
    local conjur_login="$2"
    local conjur_api_key="$3"
    local conjur_service_id="$4"
    local conjur_host_id="$5"

    echo ""
    echo ""
    echo "Processing examples directories..."
    echo "=================================="

    for dir in "${EXAMPLE_DIRS[@]}"; do
        local tfvars_path="${REPO_ROOT}/examples/${dir}/${TFVARS_FILENAME}"

        if [[ -f "${tfvars_path}" ]]; then
            echo ""
            echo "Example: examples/${dir}"
            update_tfvars_auth "${tfvars_path}" "${authn_type}" "${conjur_login}" \
                "${conjur_api_key}" "${conjur_service_id}" "${conjur_host_id}" || true
        fi
    done
}

# Main execution
main() {
    echo "=========================================="
    echo "Set Conjur Authentication in tfvars Files"
    echo "=========================================="
    echo ""
    echo "Select Conjur authentication mode:"
    echo "  1) api  — API key auth (laptop/desktop)"
    echo "  2) iam  — AWS IAM auth (EC2 instance)"
    echo ""
    read -p "Choice [1/2]: " auth_choice

    local authn_type=""
    local conjur_login=""
    local conjur_api_key=""
    local conjur_service_id=""
    local conjur_host_id=""

    case "${auth_choice}" in
        1|api)
            authn_type="api"
            echo ""
            read -p "Enter conjur_login: " conjur_login
            conjur_api_key=$(read_secret "Enter conjur_api_key")

            if [[ -z "${conjur_login}" ]] || [[ -z "${conjur_api_key}" ]]; then
                echo ""
                echo "ERROR: Both conjur_login and conjur_api_key are required for API mode."
                exit 1
            fi
            ;;
        2|iam)
            authn_type="iam"
            echo ""
            read -p "Enter conjur_service_id [default]: " conjur_service_id
            conjur_service_id="${conjur_service_id:-default}"
            read -p "Enter conjur_host_id [host/data/your-workload]: " conjur_host_id
            conjur_host_id="${conjur_host_id:-host/data/your-workload}"
            ;;
        *)
            echo "ERROR: Invalid choice. Please enter 1 or 2."
            exit 1
            ;;
    esac

    echo ""
    echo "Auth mode: ${authn_type}"
    echo "Updating files..."

    process_terraform_code "${authn_type}" "${conjur_login}" "${conjur_api_key}" \
        "${conjur_service_id}" "${conjur_host_id}"

    process_examples "${authn_type}" "${conjur_login}" "${conjur_api_key}" \
        "${conjur_service_id}" "${conjur_host_id}"

    echo ""
    echo ""
    echo "=========================================="
    echo "Summary"
    echo "=========================================="
    echo "Auth mode:       ${authn_type}"
    echo "✓ Files updated: ${TOTAL_UPDATED}"
    echo "⊘ Files skipped: ${TOTAL_SKIPPED}"
    echo "=========================================="
    echo ""
    echo "IMPORTANT: These credentials are stored locally only."
    echo "They will NOT be uploaded to S3 by push_tfvars.sh."
    echo ""
    echo "NOTE: If the Conjur CLI is installed, its ~/.conjurrc file can"
    echo "interfere with the Terraform Conjur provider. Add this to your"
    echo "shell profile (~/.zshrc or ~/.bashrc) to prevent conflicts:"
    echo ""
    echo "  export CONJURRC=/dev/null"
    echo ""
}

main "$@"
