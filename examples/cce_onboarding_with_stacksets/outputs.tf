# ===========================
# CCE Organization Outputs
# ===========================
output "org_onboarding_id" {
  description = "The AWS Organization Onboarding ID from CyberArk CCE"
  value       = module.cce_aws_organization.org_onboarding_id
}

output "cce_scan_role_arn" {
  description = "IAM role ARN for CCE organization scanning"
  value       = module.cce_aws_organization.cce_scan_role_arn
}

output "sca_role_arn" {
  description = "IAM role ARN for Secure Cloud Access (SCA) in Management Account"
  value       = module.cce_aws_organization.sca_role_arn
}

output "dpa_role_arn" {
  description = "IAM role ARN for Secure Infrastructure Access (SIA/DPA) in Management Account"
  value       = module.cce_aws_organization.dpa_role_arn
}

# ===========================
# Discovered Accounts
# ===========================
output "member_accounts" {
  description = "Map of all discovered member accounts"
  value = {
    for id, account in local.member_accounts :
    id => {
      name   = account.name
      email  = account.email
      status = account.status
    }
  }
}

output "member_account_count" {
  description = "Total number of member accounts discovered"
  value       = length(local.member_accounts)
}

# ===========================
# StackSet
# ===========================
output "stackset_id" {
  description = "CloudFormation StackSet ID for member account IAM role deployment"
  value       = aws_cloudformation_stack_set.cce_member_account_roles.stack_set_id
}

# ===========================
# Registered Accounts
# ===========================
output "registered_accounts" {
  description = "Map of member accounts registered with CyberArk CCE"
  value = {
    for id, account in idsec_cce_aws_organization_account.member_accounts :
    id => {
      account_id = account.account_id
    }
  }
}
