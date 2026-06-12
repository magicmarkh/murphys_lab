provider "aws" {
  region     = var.aws_region
  access_key = var.conjur_authn_type == "api" ? data.conjur_secret.aws_access_key[0].value : null
  secret_key = var.conjur_authn_type == "api" ? data.conjur_secret.aws_secret_key[0].value : null

  # Prevent fallback to local ~/.aws/credentials or config
  shared_credentials_files = var.conjur_authn_type == "api" ? [] : null
  shared_config_files      = var.conjur_authn_type == "api" ? [] : null
}

terraform {
  required_version = ">= 1.8.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.2.1"  # pinned by cyberark/cce-organization/aws module (latest v0.2.3 requires ~> 0.2.1)
    }
    conjur = {
      source  = "cyberark/conjur"
      version = "~> 0.8.1"
    }
  }
}

provider "conjur" {
  appliance_url = var.conjur_appliance_url
  account       = var.conjur_account
  authn_type    = var.conjur_authn_type == "iam" ? "aws" : "api"

  # API key auth (laptop) — null when using IAM
  login   = var.conjur_authn_type == "api" ? var.conjur_login : null
  api_key = var.conjur_authn_type == "api" ? var.conjur_api_key : null

  # IAM auth (EC2) — null when using API key
  service_id = var.conjur_authn_type == "iam" ? var.conjur_service_id : null
  host_id    = var.conjur_authn_type == "iam" ? var.conjur_host_id : null
}

data "conjur_secret" "identity_client_id" {
  name = var.conjur_identity_client_id_path
}

data "conjur_secret" "identity_client_secret" {
  name = var.conjur_identity_client_secret_path
}

data "conjur_secret" "aws_access_key" {
  count = var.conjur_authn_type == "api" ? 1 : 0
  name  = var.conjur_aws_access_key_path
}

data "conjur_secret" "aws_secret_key" {
  count = var.conjur_authn_type == "api" ? 1 : 0
  name  = var.conjur_aws_secret_key_path
}

provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = data.conjur_secret.identity_client_id.value
  service_token = data.conjur_secret.identity_client_secret.value
}
