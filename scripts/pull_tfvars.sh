#!/bin/bash
set -euo pipefail

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Counters for summary
TOTAL_SUCCESS=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

# Auth counters
AUTH_UPDATED=0
AUTH_SKIPPED=0

# Function: Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo "ERROR: AWS CLI not found. Please install: https://aws.amazon.com/cli/"
        exit 1
    fi

    # Check S3 bucket access
    if ! aws s3 ls "s3://${TFVARS_S3_BUCKET}" --region "${TFVARS_S3_REGION}" &> /dev/null; then
        echo "ERROR: Cannot access S3 bucket ${TFVARS_S3_BUCKET}"
        echo "Please check your AWS credentials and permissions."
        exit 1
    fi

    echo "✓ Prerequisites validated"
}

# Function: Detect if running on an EC2 instance via IMDS
is_ec2() {
    # Try IMDSv2 token first, then fall back to IMDSv1
    local token
    token=$(curl -s -m 2 -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null) || true

    if [[ -n "${token}" ]]; then
        # IMDSv2 worked
        curl -s -m 2 -H "X-aws-ec2-metadata-token: ${token}" \
            "http://169.254.169.254/latest/meta-data/instance-id" &>/dev/null
        return $?
    else
        # Fall back to IMDSv1
        curl -s -m 2 "http://169.254.169.254/latest/meta-data/instance-id" &>/dev/null
        return $?
    fi
}

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

# Function: Update a single tfvars file with auth config
update_tfvars_auth() {
    local file_path="$1"
    local authn_type="$2"
    local conjur_login="$3"
    local conjur_api_key="$4"
    local conjur_service_id="$5"
    local conjur_host_id="$6"

    if grep -qE '^conjur_authn_type[[:space:]]*=' "${file_path}" || \
       grep -qE '^conjur_login[[:space:]]*=' "${file_path}" || \
       grep -qE '^conjur_api_key[[:space:]]*=' "${file_path}"; then

        update_field "${file_path}" "conjur_authn_type" "${authn_type}"
        update_field "${file_path}" "conjur_login" "${conjur_login}"
        update_field "${file_path}" "conjur_api_key" "${conjur_api_key}"
        update_field "${file_path}" "conjur_service_id" "${conjur_service_id}"
        update_field "${file_path}" "conjur_host_id" "${conjur_host_id}"

        echo "  ✓ Auth configured: ${file_path}"
        ((AUTH_UPDATED++))
        return 0
    else
        echo "  ⊘ No Conjur auth fields: ${file_path}"
        ((AUTH_SKIPPED++))
        return 1
    fi
}

# Function: Configure Conjur auth in all downloaded tfvars files
configure_conjur_auth() {
    local authn_type="$1"
    local conjur_login="$2"
    local conjur_api_key="$3"
    local conjur_service_id="$4"
    local conjur_host_id="$5"

    echo ""
    echo "Configuring Conjur auth (${authn_type}) in downloaded files..."
    echo "=============================================================="

    for dir in "${TERRAFORM_CODE_DIRS[@]}"; do
        local tfvars_path="${REPO_ROOT}/terraform_code/${dir}/${TFVARS_FILENAME}"
        if [[ -f "${tfvars_path}" ]]; then
            update_tfvars_auth "${tfvars_path}" "${authn_type}" "${conjur_login}" \
                "${conjur_api_key}" "${conjur_service_id}" "${conjur_host_id}" || true
        fi
    done

    for dir in "${EXAMPLE_DIRS[@]}"; do
        local tfvars_path="${REPO_ROOT}/examples/${dir}/${TFVARS_FILENAME}"
        if [[ -f "${tfvars_path}" ]]; then
            update_tfvars_auth "${tfvars_path}" "${authn_type}" "${conjur_login}" \
                "${conjur_api_key}" "${conjur_service_id}" "${conjur_host_id}" || true
        fi
    done
}

# Function: Download file from S3
download_file() {
    local s3_key="$1"
    local local_path="$2"
    local file_type="$3"  # "tfvars" or "backend"

    # Check if file exists in S3
    if aws s3 ls "s3://${TFVARS_S3_BUCKET}/${s3_key}" --region "${TFVARS_S3_REGION}" &> /dev/null; then
        # Create local directory if needed
        mkdir -p "$(dirname "${local_path}")"

        # Download file
        if aws s3 cp "s3://${TFVARS_S3_BUCKET}/${s3_key}" "${local_path}" --region "${TFVARS_S3_REGION}" --quiet; then
            echo "  ✓ Downloaded: ${local_path}"
            ((TOTAL_SUCCESS++))
            return 0
        else
            echo "  ✗ Failed to download: ${s3_key}"
            ((TOTAL_FAILED++))
            return 1
        fi
    else
        echo "  ⊘ Not found in S3: ${s3_key}"
        ((TOTAL_SKIPPED++))
        return 2
    fi
}

# Function: Process terraform_code directories
process_terraform_code() {
    echo ""
    echo "Processing terraform_code directories..."
    echo "========================================"

    for dir in "${TERRAFORM_CODE_DIRS[@]}"; do
        local base_path="${REPO_ROOT}/terraform_code/${dir}"
        local s3_base="${TFVARS_S3_PREFIX}/terraform_code/${dir}"

        echo ""
        echo "Module: terraform_code/${dir}"

        # Download terraform.tfvars
        download_file "${s3_base}/${TFVARS_FILENAME}" "${base_path}/${TFVARS_FILENAME}" "tfvars" || true

        # Download backend.tf
        download_file "${s3_base}/${BACKEND_FILENAME}" "${base_path}/${BACKEND_FILENAME}" "backend" || true
    done
}

# Function: Process examples directories
process_examples() {
    echo ""
    echo ""
    echo "Processing examples directories..."
    echo "=================================="

    for dir in "${EXAMPLE_DIRS[@]}"; do
        local base_path="${REPO_ROOT}/examples/${dir}"
        local s3_base="${TFVARS_S3_PREFIX}/examples/${dir}"

        echo ""
        echo "Example: examples/${dir}"

        # Download terraform.tfvars
        download_file "${s3_base}/${TFVARS_FILENAME}" "${base_path}/${TFVARS_FILENAME}" "tfvars" || true
    done
}

# Main execution
main() {
    echo "=========================================="
    echo "Pulling tfvars and backend.tf from S3"
    echo "=========================================="
    echo "Bucket: ${TFVARS_S3_BUCKET}"
    echo "Region: ${TFVARS_S3_REGION}"
    echo "Prefix: ${TFVARS_S3_PREFIX}"
    echo "=========================================="
    echo ""

    check_prerequisites

    process_terraform_code

    process_examples

    echo ""
    echo ""
    echo "=========================================="
    echo "Pull Summary"
    echo "=========================================="
    echo "✓ Successfully downloaded: ${TOTAL_SUCCESS} files"
    echo "✗ Failed to download: ${TOTAL_FAILED} files"
    echo "⊘ Not found in S3: ${TOTAL_SKIPPED} files"
    echo "=========================================="

    # --- Conjur Auth Setup ---
    echo ""
    echo "=========================================="
    echo "Conjur Authentication Setup"
    echo "=========================================="

    local authn_type=""
    local conjur_login=""
    local conjur_api_key=""
    local conjur_service_id=""
    local conjur_host_id=""

    if is_ec2; then
        echo ""
        echo "EC2 instance detected — defaulting to IAM authentication."
        echo ""
        echo "Select Conjur authentication mode:"
        echo "  1) iam  — AWS IAM auth (recommended on EC2)"
        echo "  2) api  — API key auth"
        echo ""
        read -p "Choice [1/2] (default: 1): " auth_choice
        auth_choice="${auth_choice:-1}"
    else
        echo ""
        echo "Local workstation detected."
        echo ""
        echo "Select Conjur authentication mode:"
        echo "  1) api  — API key auth (recommended on laptop)"
        echo "  2) iam  — AWS IAM auth"
        echo ""
        read -p "Choice [1/2] (default: 1): " auth_choice
        auth_choice="${auth_choice:-1}"
    fi

    if is_ec2; then
        case "${auth_choice}" in
            1|iam)
                authn_type="iam"
                echo ""
                read -p "Enter conjur_service_id [prod]: " conjur_service_id
                conjur_service_id="${conjur_service_id:-prod}"
                read -p "Enter conjur_host_id [host/data/murphys-tf]: " conjur_host_id
                conjur_host_id="${conjur_host_id:-host/data/murphys-tf}"
                ;;
            2|api)
                authn_type="api"
                echo ""
                read -p "Enter conjur_login [host/data/murphys-tf]: " conjur_login
                conjur_login="${conjur_login:-host/data/murphys-tf}"
                conjur_api_key=$(read_secret "Enter conjur_api_key")
                if [[ -z "${conjur_api_key}" ]]; then
                    echo "ERROR: conjur_api_key is required for API mode."
                    exit 1
                fi
                ;;
            *)
                echo "ERROR: Invalid choice."
                exit 1
                ;;
        esac
    else
        case "${auth_choice}" in
            1|api)
                authn_type="api"
                echo ""
                read -p "Enter conjur_login [host/data/murphys-tf]: " conjur_login
                conjur_login="${conjur_login:-host/data/murphys-tf}"
                conjur_api_key=$(read_secret "Enter conjur_api_key")
                if [[ -z "${conjur_api_key}" ]]; then
                    echo "ERROR: conjur_api_key is required for API mode."
                    exit 1
                fi
                ;;
            2|iam)
                authn_type="iam"
                echo ""
                read -p "Enter conjur_service_id [prod]: " conjur_service_id
                conjur_service_id="${conjur_service_id:-prod}"
                read -p "Enter conjur_host_id [host/data/murphys-tf]: " conjur_host_id
                conjur_host_id="${conjur_host_id:-host/data/murphys-tf}"
                ;;
            *)
                echo "ERROR: Invalid choice."
                exit 1
                ;;
        esac
    fi

    configure_conjur_auth "${authn_type}" "${conjur_login}" "${conjur_api_key}" \
        "${conjur_service_id}" "${conjur_host_id}"

    echo ""
    echo "=========================================="
    echo "Auth Summary"
    echo "=========================================="
    echo "Mode:            ${authn_type}"
    echo "✓ Files updated: ${AUTH_UPDATED}"
    echo "⊘ Files skipped: ${AUTH_SKIPPED}"
    echo "=========================================="
    echo ""
    echo "NOTE: If the Conjur CLI is installed, ensure CONJURRC=/dev/null is"
    echo "set in your shell to prevent ~/.conjurrc from interfering with Terraform."
    echo ""
}

main "$@"
