terraform {
  required_providers {
    sca = {
      # Provider version is 1.0.0
      source = "cyberark/sca/sca"
      version = ">= 1.0.0"
    }
  }
}

provider "sca" {
  auth_url             = var.auth_url
  tenant_domain_name   = var.tenant_domain_name
  platform_domain_name = var.platform_domain_name
  username             = var.username
  password             = var.password
  debug                = true
}

/*
data "sca_discovery" "discovery_example" {
  csp             = var.csp
  organization_id = var.root_organization_id
  account_info    = {
    id          = var.workspace_id
    new_account = var.new_account
  }
}
*/

resource "sca_policy" "policy_example" {

  //depends_on = [data.sca_discovery.discovery_example]
  name         = var.policy_name
  description  = var.policy_description
  csp          = var.csp
  roles        = var.roles
  identities   = var.identities
  access_rules = var.access_rules
  end_date     = var.end_date
  start_date   = var.start_date
}
