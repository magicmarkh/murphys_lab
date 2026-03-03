terraform {
  required_version = ">= 1.3.0"
  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.1.17"
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
  name = "data/vault/m-priv-svc-accts/svc_tfautomation/username"
}

data "conjur_secret" "identity_client_secret" {
  name = "data/vault/m-priv-svc-accts/svc_tfautomation/password"
}

provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = data.conjur_secret.identity_client_id.value
  service_token = data.conjur_secret.identity_client_secret.value
}