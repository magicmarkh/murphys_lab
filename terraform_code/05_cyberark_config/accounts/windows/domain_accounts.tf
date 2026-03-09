# ===========================
# Domain Admin Safe
# ===========================
resource "idsec_pcloud_safe" "m-domain-admins" {
  safe_name                = "m-domain-admins"
  description              = ""
  number_of_days_retention = 7

  lifecycle {
    prevent_destroy = true
  }
}

# ===========================
# Domain Admin Accounts
# ===========================
resource "idsec_pcloud_account" "domain_admin_accounts" {
  for_each = var.domain_admin_accounts

  platform_id = each.value.platform_id
  username    = each.value.username
  address     = each.value.address
  secret      = each.value.secret
  safe_name   = idsec_pcloud_safe.m-domain-admins.safe_name
  name        = "domain-admin-${each.value.username}"

  # Remote machine access restrictions (v0.1.17+ syntax)
  remote_machines                      = try(each.value.remote_machines, [])
  access_restricted_to_remote_machines = try(length(each.value.remote_machines) > 0, false)

  lifecycle {
    ignore_changes = [
      secret,
      name,
      account_id,
      created_time,
      category_modification_time,
      secret_type,
      platform_account_properties,
      remote_machines,
      access_restricted_to_remote_machines,
      status
    ]
  }
}

# ===========================
# Domain Server Admin Safe
# ===========================
resource "idsec_pcloud_safe" "m-domain-server-admins" {
  safe_name                = "m-domain-server-admins"
  description              = ""
  number_of_days_retention = 7
}

# ===========================
# Domain Server Admin Accounts
# ===========================
resource "idsec_pcloud_account" "domain_server_admin_accounts" {
  for_each = var.domain_server_admin_accounts

  platform_id = each.value.platform_id
  username    = each.value.username
  address     = each.value.address
  secret      = each.value.secret
  safe_name   = idsec_pcloud_safe.m-domain-server-admins.safe_name
  name        = "domain-server-admin-${each.value.username}"

  # Remote machine access restrictions (v0.1.17+ syntax)
  remote_machines                      = try(each.value.remote_machines, [])
  access_restricted_to_remote_machines = try(length(each.value.remote_machines) > 0, false)

  lifecycle {
    ignore_changes = [
      secret,
      name,
      account_id,
      created_time,
      category_modification_time,
      secret_type,
      platform_account_properties,
      remote_machines,
      access_restricted_to_remote_machines,
      status
    ]
  }
}

# ===========================
# Domain User Safe
# ===========================
resource "idsec_pcloud_safe" "m-domain-user" {
  safe_name                = "m-domain-user"
  description              = ""
  number_of_days_retention = 7
}

# ===========================
# Domain User Accounts
# ===========================
resource "idsec_pcloud_account" "domain_user_accounts" {
  for_each = var.domain_user_accounts

  platform_id = each.value.platform_id
  username    = each.value.username
  address     = each.value.address
  secret      = each.value.secret
  safe_name   = idsec_pcloud_safe.m-domain-user.safe_name
  name        = "domain-user-${each.value.username}"

  # Remote machine access restrictions (v0.1.17+ syntax)
  remote_machines                      = try(each.value.remote_machines, [])
  access_restricted_to_remote_machines = try(length(each.value.remote_machines) > 0, false)

  lifecycle {
    ignore_changes = [
      secret,
      name,
      account_id,
      created_time,
      category_modification_time,
      secret_type,
      platform_account_properties,
      remote_machines,
      access_restricted_to_remote_machines,
      status
    ]
  }
}
