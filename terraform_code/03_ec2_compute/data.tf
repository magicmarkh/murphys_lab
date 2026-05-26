# =====================================================================
# Conjur Data Sources - Shared credentials for EC2 resources
# =====================================================================
# These data sources retrieve secrets from Conjur that can be used
# across multiple EC2 instance types (connectors, targets, etc.)

# Domain join credentials
data "conjur_secret" "domain_join_username" {
  name = var.conjur_domain_join_username_path
}

data "conjur_secret" "domain_join_password" {
  name = var.conjur_domain_join_password_path
}

# Identity credentials
data "conjur_secret" "identity_client_id" {
  name = var.conjur_identity_client_id_path
}

data "conjur_secret" "identity_client_secret" {
  name = var.conjur_identity_client_secret_path
}

# AWS credentials (only fetched in API mode; IAM mode uses instance role)
data "conjur_secret" "aws_access_key" {
  count = var.conjur_authn_type == "api" ? 1 : 0
  name  = var.conjur_aws_access_key_path
}

data "conjur_secret" "aws_secret_key" {
  count = var.conjur_authn_type == "api" ? 1 : 0
  name  = var.conjur_aws_secret_key_path
}

# AWS PEM key for SSH access
data "conjur_secret" "aws_pem_key" {
  name = var.conjur_aws_pem_key_path
}

# =====================================================================
# Remote State Data Sources
# =====================================================================

# Data source to reference CyberArk connector pools outputs
data "terraform_remote_state" "cyberark_connector_pools" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = var.cyberark_connector_pools_state_key
    region = var.state_region
  }
}
