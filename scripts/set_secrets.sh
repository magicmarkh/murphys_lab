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

# Function to read multi-line SSH private key from user
read_ssh_key() {
    local ssh_key=""

    echo "Paste your SSH private key below."
    echo "The key should start with '-----BEGIN RSA PRIVATE KEY-----'"
    echo "Paste the entire key including BEGIN and END lines, then press Ctrl+D on a new line:"
    echo ""

    # Read multi-line input until EOF (Ctrl+D)
    ssh_key=$(cat)

    echo "$ssh_key"
}

# Function to update SSH key file
update_ssh_key() {
    local ssh_key="$1"
    local key_file="${REPO_ROOT}/${SSH_KEY_PATH}/${SSH_KEY_FILENAME}"

    # Check if key content is provided
    if [[ -z "$ssh_key" ]]; then
        echo "✗ No SSH key provided, skipping..." >&2
        return 1
    fi

    # Validate key format (basic check for BEGIN line)
    if ! echo "$ssh_key" | grep -q "BEGIN.*PRIVATE KEY"; then
        echo "✗ Invalid SSH key format (missing BEGIN line)" >&2
        return 1
    fi

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$key_file")"

    # Write key to file
    echo "$ssh_key" > "$key_file"

    if [[ $? -eq 0 ]]; then
        # Set correct permissions (readable only by owner)
        chmod 600 "$key_file"
        echo "✓ SSH key written to: ${key_file}"
        echo "✓ Permissions set to 600"
        return 0
    else
        echo "✗ Failed to write SSH key to file" >&2
        return 1
    fi
}

# Function: Update tfvars file with secrets
update_tfvars_secrets() {
    local file_path="$1"
    local conjur_login="$2"
    local conjur_api_key="$3"

    # Check if file has empty conjur_login or conjur_api_key
    if grep -qE '^conjur_login[[:space:]]*=[[:space:]]*""' "${file_path}" || \
       grep -qE '^conjur_api_key[[:space:]]*=[[:space:]]*""' "${file_path}"; then

        # Update conjur_login
        sed -i.bak -E "s|^(conjur_login[[:space:]]*=[[:space:]]*).*|\1\"${conjur_login}\"|" "${file_path}"

        # Update conjur_api_key
        sed -i.bak -E "s|^(conjur_api_key[[:space:]]*=[[:space:]]*).*|\1\"${conjur_api_key}\"|" "${file_path}"

        # Remove backup file
        rm -f "${file_path}.bak"

        echo "  ✓ Updated: ${file_path}"
        ((TOTAL_UPDATED++))
        return 0
    else
        echo "  ⊘ No empty secrets found (or fields don't exist): ${file_path}"
        ((TOTAL_SKIPPED++))
        return 1
    fi
}

# Function: Process terraform_code directories
process_terraform_code() {
    local conjur_login="$1"
    local conjur_api_key="$2"

    echo ""
    echo "Processing terraform_code directories..."
    echo "========================================"

    for dir in "${TERRAFORM_CODE_DIRS[@]}"; do
        local tfvars_path="${REPO_ROOT}/terraform_code/${dir}/${TFVARS_FILENAME}"

        if [[ -f "${tfvars_path}" ]]; then
            echo ""
            echo "Module: terraform_code/${dir}"
            update_tfvars_secrets "${tfvars_path}" "${conjur_login}" "${conjur_api_key}" || true
        fi
    done
}

# Function: Process examples directories
process_examples() {
    local conjur_login="$1"
    local conjur_api_key="$2"

    echo ""
    echo ""
    echo "Processing examples directories..."
    echo "=================================="

    for dir in "${EXAMPLE_DIRS[@]}"; do
        local tfvars_path="${REPO_ROOT}/examples/${dir}/${TFVARS_FILENAME}"

        if [[ -f "${tfvars_path}" ]]; then
            echo ""
            echo "Example: examples/${dir}"
            update_tfvars_secrets "${tfvars_path}" "${conjur_login}" "${conjur_api_key}" || true
        fi
    done
}

# Main execution
main() {
    echo "=========================================="
    echo "Set Conjur Secrets in tfvars Files"
    echo "=========================================="
    echo ""
    echo "This script will populate conjur_login and conjur_api_key"
    echo "in all terraform.tfvars files that have empty values."
    echo ""

    # Prompt for SSH key (optional)
    echo "=========================================="
    echo "SSH Key Setup"
    echo "=========================================="
    echo ""
    echo "Do you want to set up the SSH private key? (y/n)"
    read -p "> " setup_ssh_key

    if [[ "$setup_ssh_key" =~ ^[Yy]$ ]]; then
        ssh_key=$(read_ssh_key)
        echo ""
        update_ssh_key "$ssh_key"
        echo ""
    else
        echo "Skipping SSH key setup..."
        echo ""
    fi

    echo "=========================================="
    echo "Conjur Credentials Setup"
    echo "=========================================="
    echo ""

    # Read secrets from user
    read -p "Enter conjur_login: " conjur_login
    conjur_api_key=$(read_secret "Enter conjur_api_key")

    # Validate inputs
    if [[ -z "${conjur_login}" ]] || [[ -z "${conjur_api_key}" ]]; then
        echo ""
        echo "ERROR: Both conjur_login and conjur_api_key are required."
        exit 1
    fi

    echo ""
    echo "Updating files with provided secrets..."

    process_terraform_code "${conjur_login}" "${conjur_api_key}"

    process_examples "${conjur_login}" "${conjur_api_key}"

    echo ""
    echo ""
    echo "=========================================="
    echo "Summary"
    echo "=========================================="
    echo "✓ Files updated: ${TOTAL_UPDATED}"
    echo "⊘ Files skipped: ${TOTAL_SKIPPED}"
    echo "=========================================="
    echo ""
    echo "IMPORTANT: These credentials are stored locally only."
    echo "They will NOT be uploaded to S3 by push_tfvars.sh."
    echo ""
}

main "$@"
