#!/bin/bash
set -euo pipefail

# Source shared configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Counters for summary
TOTAL_SUCCESS=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0

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
        download_file "${s3_base}/${TFVARS_FILENAME}" "${base_path}/${TFVARS_FILENAME}" "tfvars"

        # Download backend.tf
        download_file "${s3_base}/${BACKEND_FILENAME}" "${base_path}/${BACKEND_FILENAME}" "backend"
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
        download_file "${s3_base}/${TFVARS_FILENAME}" "${base_path}/${TFVARS_FILENAME}" "tfvars"
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
    echo ""
    echo "IMPORTANT: Conjur credentials are NOT included in downloaded files."
    echo "Run './scripts/set_secrets.sh' to populate conjur_login and conjur_api_key."
    echo ""
}

main "$@"
