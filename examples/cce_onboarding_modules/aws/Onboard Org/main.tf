terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.3.3"
    }
   # conjur = {
    #  source  = "cyberark/conjur"
     # version = "~> 0.8.1"
    #}
  }
}
/*
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
*/

provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = var.idsec_service_user
  service_token = var.idsec_service_token
}

provider "aws" {
  region = "us-east-2"
}

module "cce_aws_organization" {
  source  = "cyberark/cce-organization/aws"
  version = "~> 0.2.0"

  organization_id       = var.organization_id
  management_account_id = var.mgmt_acct
  organization_root_id  = var.organization_root_id
  display_name          = var.display_name

  sia = { enable = false }
  sca = {
    enable     = true
    sso_enable = false
    sso_region = var.aws_region
  }
}

# ===========================
# Fetch All AWS Organization Accounts
# ===========================
data "aws_organizations_organization" "org" {}

# Extract all account IDs from the organization
locals {
  # Get all accounts and create a map keyed by account ID
  all_accounts = {
    for account in data.aws_organizations_organization.org.accounts :
    account.id => account
  }

  # Exclude the management account from onboarding (already handled by the org module)
  member_accounts = {
    for id, account in local.all_accounts :
    id => account
    if id != var.mgmt_acct
  }
}

# ===========================
# Onboard All Member Accounts to CCE
# ===========================
resource "idsec_cce_aws_organization_account" "member_accounts" {
  for_each = local.member_accounts

  account_id             = each.value.id
  #parent_organization_id = module.cce_aws_organization.org_onboarding_id
  parent_organization_id =  var.organization_id
  display_name           = each.value.name != "" ? each.value.name : "Account-${each.value.id}"

  services = [{ service_name = "sca" }]

  # Wait for organization onboarding to complete first
  depends_on = [module.cce_aws_organization]
}
