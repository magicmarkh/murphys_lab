# ===========================
# Provider Configuration
# ===========================
provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = var.idsec_service_user
  service_token = var.idsec_service_token
}

provider "aws" {
  region = var.aws_region
}

# ===========================
# Organization Onboarding
# ===========================
module "cce_aws_organization" {
  source  = "cyberark/cce-organization/aws"
  version = "~> 0.2.0"

  organization_id       = var.organization_id
  management_account_id = var.management_account_id
  organization_root_id  = var.organization_root_id
  display_name          = var.display_name

  sia = { enable = var.enable_sia }
  sca = {
    enable     = var.enable_sca
    sso_enable = var.sca_sso_enable
    sso_region = var.sca_sso_enable ? var.sca_sso_region : null
  }
}

# ===========================
# Account Discovery
# ===========================
data "aws_organizations_organization" "org" {}

locals {
  all_accounts = {
    for account in data.aws_organizations_organization.org.accounts :
    account.id => account
  }

  member_accounts = {
    for id, account in local.all_accounts :
    id => account
    if id != var.management_account_id
  }
}

# ===========================
# CyberArk Tenant & Organization Details
# ===========================
data "idsec_cce_aws_tenant_service_details" "tenant" {}

data "idsec_cce_aws_organization" "org_data" {
  id = module.cce_aws_organization.org_onboarding_id
}

locals {
  tenant_id              = data.idsec_cce_aws_tenant_service_details.tenant.tenant_id
  dpa_service_account_id = try(data.idsec_cce_aws_tenant_service_details.tenant.services_details.dpa.service_account_id, "")
  sca_service_account_id = try(data.idsec_cce_aws_tenant_service_details.tenant.services_details.sca.service_account_id, "")
  sca_service_stage      = try(data.idsec_cce_aws_tenant_service_details.tenant.services_details.sca.service_stage, "")
  sca_role_name          = var.enable_sca ? regex("^arn:aws:iam::[0-9]{12}:role/(.+)$", module.cce_aws_organization.sca_role_arn)[0] : ""
}

# ===========================
# StackSet: Deploy IAM Roles to All Member Accounts
# ===========================
# Prerequisite (one-time):
#   aws organizations enable-aws-service-access \
#     --service-principal member.org.stacksets.cloudformation.amazonaws.com

resource "aws_cloudformation_stack_set" "cce_member_account_roles" {
  name             = "cce-member-account-iam-roles"
  description      = "CyberArk CCE IAM roles for SCA/SIA in organization member accounts"
  permission_model = "SERVICE_MANAGED"
  call_as          = "SELF"

  template_body = file("${path.module}/templates/member_account_iam.yaml")

  parameters = {
    TenantId            = local.tenant_id
    DPAServiceAccountId = local.dpa_service_account_id
    SCAServiceAccountId = local.sca_service_account_id
    ServiceStage        = local.sca_service_stage
    SCARoleName         = local.sca_role_name
    OrgAccountId        = var.management_account_id
    EnableSIA           = tostring(var.enable_sia)
    EnableSCA           = tostring(var.enable_sca)
    SSOEnable           = tostring(var.sca_sso_enable)
  }

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  capabilities = ["CAPABILITY_NAMED_IAM"]

  depends_on = [module.cce_aws_organization]

  lifecycle {
    ignore_changes = [administration_role_arn]
  }
}

resource "aws_cloudformation_stack_set_instance" "all_member_accounts" {
  stack_set_name = aws_cloudformation_stack_set.cce_member_account_roles.name
  call_as        = "SELF"

  deployment_targets {
    organizational_unit_ids = [var.organization_root_id]
  }

  depends_on = [aws_cloudformation_stack_set.cce_member_account_roles]
}

# ===========================
# Register Member Accounts with CyberArk API
# ===========================
resource "idsec_cce_aws_organization_account" "member_accounts" {
  for_each = local.member_accounts

  parent_organization_id = module.cce_aws_organization.org_onboarding_id
  account_id             = each.value.id

  parameters = data.idsec_cce_aws_organization.org_data.parameters

  services = [
    {
      service_name = "sca"
      resources = {
        scaPowerRoleArn = "arn:aws:iam::${each.value.id}:role/${local.sca_role_name}"
        ssoEnable       = tostring(var.sca_sso_enable)
        ssoRegion       = var.sca_sso_enable ? var.sca_sso_region : null
      }
    }
  ]

  depends_on = [aws_cloudformation_stack_set_instance.all_member_accounts]
}
