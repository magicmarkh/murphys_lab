# =====================================================================
# AWS Access Keys - m-conjur-automation Safe
# =====================================================================

# =====================================================================
# Safe for AWS Access Keys
# =====================================================================
resource "idsec_pcloud_safe" "m-conjur-automation" {
  safe_name                = "m-conjur-automation"
  description              = ""
  number_of_days_retention = 7
  auto_purge_enabled       = false
  olac_enabled             = false
  location                 = "\\"
}

# =====================================================================
# Safe Members
# =====================================================================
resource "idsec_pcloud_safe_member" "conjur_automation_members" {
  for_each = var.aws_access_key_safe_members

  safe_id                    = idsec_pcloud_safe.m-conjur-automation.safe_id
  safe_name                  = idsec_pcloud_safe.m-conjur-automation.safe_name
  member_name                = each.value.member_name
  member_type                = each.value.member_type
  search_in                  = try(each.value.search_in, null)
  membership_expiration_date = try(each.value.membership_expiration_date, null)
  permission_set             = each.value.permission_set
}

# =====================================================================
# AWS Access Key Account
# =====================================================================
resource "idsec_pcloud_account" "us-ent-east-automation" {
  platform_id = var.aws_access_key_platform_id
  username    = var.aws_access_key_username
  address     = var.aws_access_key_address
  secret      = var.aws_access_key_secret
  safe_name   = idsec_pcloud_safe.m-conjur-automation.safe_name
  name        = var.aws_access_key_account_name

  # Lifecycle rule to ignore changes to computed/immutable fields
  # This account was imported from existing CyberArk resource
  lifecycle {
    ignore_changes = [
      address,                     # Cannot be modified on existing accounts
      account_id,                  # Computed by CyberArk
      created_time,                # Computed by CyberArk
      category_modification_time,  # Computed by CyberArk
      platform_account_properties, # Managed by CyberArk platform
      secret_type,                 # Computed field
      status                       # Computed field
    ]
  }

  depends_on = [
    idsec_pcloud_safe.m-conjur-automation,
    idsec_pcloud_safe_member.conjur_automation_members
  ]
}
