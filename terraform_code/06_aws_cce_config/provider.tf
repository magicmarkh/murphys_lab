provider "aws" {
  region     = var.aws_region
  access_key = data.conjur_secret.aws_access_key.value
  secret_key = data.conjur_secret.aws_secret_key.value

  # Prevent fallback to local ~/.aws/credentials or config
  shared_credentials_files = []
  shared_config_files      = []
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
      version = "~> 0.3.3"
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
  api_key       = var.conjur_api_key
  authn_type    = "api"
  login         = var.conjur_login
}

data "conjur_secret" "identity_client_id" {
  name = var.conjur_identity_client_id_path
}

data "conjur_secret" "identity_client_secret" {
  name = var.conjur_identity_client_secret_path
}

data "conjur_secret" "aws_access_key" {
  name = var.conjur_aws_access_key_path
}

data "conjur_secret" "aws_secret_key" {
  name = var.conjur_aws_secret_key_path
}

provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = data.conjur_secret.identity_client_id.value
  service_token = data.conjur_secret.identity_client_secret.value
}
