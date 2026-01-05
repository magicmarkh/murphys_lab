provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.36"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.1.7"
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
  name = "data/vault/m-priv-svc-accts/svc_sca_api/username"
}

data "conjur_secret" "identity_client_secret" {
  name = "data/vault/m-priv-svc-accts/svc_sca_api/password"
}

output "identity_client_id_value" {
  value     = data.conjur_secret.identity_client_id.value
  sensitive = true
}

output "identity_client_secret_value" {
  value     = data.conjur_secret.identity_client_secret.value
  sensitive = true
}

provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = var.identity_client_id
  service_token = var.identity_client_secret
}
