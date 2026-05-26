#!/bin/bash
set -euo pipefail

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Counters for summary
TOTAL_SUCCESS=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

# Temporary directory for sanitized files
TEMP_DIR=""

# Function: Cleanup on exit
cleanup() {
    if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
}
trap cleanup EXIT

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

# Function: Sanitize tfvars file
sanitize_tfvars() {
    local input_file="$1"
    local output_file="$2"

    # Copy file to temp location
    cp "${input_file}" "${output_file}"

    # Clear sensitive fields using sed
    # Pattern matches: field = "..." or field         = "..."
    sed -i.bak -E 's/^(conjur_login[[:space:]]*=[[:space:]]*).*/\1""/' "${output_file}"
    sed -i.bak -E 's/^(conjur_api_key[[:space:]]*=[[:space:]]*).*/\1""/' "${output_file}"
    sed -i.bak -E 's/^(conjur_service_id[[:space:]]*=[[:space:]]*).*/\1""/' "${output_file}"
    sed -i.bak -E 's/^(conjur_host_id[[:space:]]*=[[:space:]]*).*/\1""/' "${output_file}"
    # Reset auth type to default so pulled files start in API mode
    sed -i.bak -E 's/^(conjur_authn_type[[:space:]]*=[[:space:]]*).*/\1"api"/' "${output_file}"

    # Remove backup file
    rm -f "${output_file}.bak"
}

# Function: Upload file to S3
upload_file() {
    local local_path="$1"
    local s3_key="$2"
    local file_type="$3"  # "tfvars" or "backend"

    # Check if local file exists
    if [[ ! -f "${local_path}" ]]; then
        echo "  ⊘ Local file not found: ${local_path}"
        ((TOTAL_SKIPPED++))
        return 2
    fi

    # Upload file
    if aws s3 cp "${local_path}" "s3://${TFVARS_S3_BUCKET}/${s3_key}" --region "${TFVARS_S3_REGION}" --quiet; then
        echo "  ✓ Uploaded: ${s3_key}"
        ((TOTAL_SUCCESS++))
        return 0
    else
        echo "  ✗ Failed to upload: ${local_path}"
        ((TOTAL_FAILED++))
        return 1
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

        # Process terraform.tfvars
        if [[ -f "${base_path}/${TFVARS_FILENAME}" ]]; then
            local temp_tfvars="${TEMP_DIR}/$(echo ${dir} | tr '/' '_')_${TFVARS_FILENAME}"
            sanitize_tfvars "${base_path}/${TFVARS_FILENAME}" "${temp_tfvars}"
            upload_file "${temp_tfvars}" "${s3_base}/${TFVARS_FILENAME}" "tfvars" || true
        else
            echo "  ⊘ Local tfvars not found: ${base_path}/${TFVARS_FILENAME}"
            ((TOTAL_SKIPPED++))
        fi

        # Upload backend.tf (no sanitization needed)
        if [[ -f "${base_path}/${BACKEND_FILENAME}" ]]; then
            upload_file "${base_path}/${BACKEND_FILENAME}" "${s3_base}/${BACKEND_FILENAME}" "backend" || true
        else
            echo "  ⊘ Local backend.tf not found: ${base_path}/${BACKEND_FILENAME}"
            ((TOTAL_SKIPPED++))
        fi
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

        # Process terraform.tfvars
        if [[ -f "${base_path}/${TFVARS_FILENAME}" ]]; then
            local temp_tfvars="${TEMP_DIR}/$(echo ${dir} | tr '/' '_')_${TFVARS_FILENAME}"
            sanitize_tfvars "${base_path}/${TFVARS_FILENAME}" "${temp_tfvars}"
            upload_file "${temp_tfvars}" "${s3_base}/${TFVARS_FILENAME}" "tfvars" || true
        else
            echo "  ⊘ Local tfvars not found: ${base_path}/${TFVARS_FILENAME}"
            ((TOTAL_SKIPPED++))
        fi
    done
}

# Main execution
main() {
    echo "=========================================="
    echo "Pushing tfvars and backend.tf to S3"
    echo "=========================================="
    echo "Bucket: ${TFVARS_S3_BUCKET}"
    echo "Region: ${TFVARS_S3_REGION}"
    echo "Prefix: ${TFVARS_S3_PREFIX}"
    echo "=========================================="
    echo ""
    echo "WARNING: This will upload sanitized tfvars files to S3."
    echo "Sensitive fields (conjur_login, conjur_api_key, conjur_service_id, conjur_host_id) will be cleared."
    echo "conjur_authn_type will be reset to 'api'."
    echo "backend.tf files will be uploaded as-is."
    echo ""
    read -p "Continue? (yes/no): " confirm

    if [[ "${confirm}" != "yes" ]]; then
        echo "Aborted."
        exit 0
    fi

    check_prerequisites

    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    echo "Using temporary directory: ${TEMP_DIR}"

    process_terraform_code

    process_examples

    echo ""
    echo ""
    echo "=========================================="
    echo "Push Summary"
    echo "=========================================="
    echo "✓ Successfully uploaded: ${TOTAL_SUCCESS} files"
    echo "✗ Failed to upload: ${TOTAL_FAILED} files"
    echo "⊘ Skipped (not found): ${TOTAL_SKIPPED} files"
    echo "=========================================="
    echo ""
    echo "REMINDER: Sensitive credentials were cleared before upload."
    echo "Your local files remain unchanged."
    echo ""
}

main "$@"
