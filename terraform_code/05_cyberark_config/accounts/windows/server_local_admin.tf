resource "idsec_pcloud_safe" "m-server-local-admin" {
  safe_name                = "m-win-svr-local-admins"
  description              = "Windows Server Sid 500 Accounts"
  number_of_days_retention = 7
}

# Add members to the safe with permissions
resource "idsec_pcloud_safe_member" "members" {
  for_each = var.safe_members

  safe_id                    = idsec_pcloud_safe.m-server-local-admin.safe_id
  safe_name                  = idsec_pcloud_safe.m-server-local-admin.safe_name
  member_name                = each.value.member_name
  member_type                = each.value.member_type
  search_in                  = try(each.value.search_in, null)
  membership_expiration_date = try(each.value.membership_expiration_date, null)
  permission_set             = each.value.permission_set

  lifecycle {
    ignore_changes = [
      is_expired_membership_enabled,
      is_predefined_user,
      is_read_only,
      member_id,
      membership_expiration_date,
      permissions,
      safe_number
    ]
  }
}
/*
  permissions = {
    use_accounts                               = try(each.value.permissions.use_accounts, false)
    retrieve_accounts                          = try(each.value.permissions.retrieve_accounts, false)
    list_accounts                              = try(each.value.permissions.list_accounts, false)
    add_accounts                               = try(each.value.permissions.add_accounts, false)
    update_account_content                     = try(each.value.permissions.update_account_content, false)
    update_account_properties                  = try(each.value.permissions.update_account_properties, false)
    initiate_cpm_account_management_operations = try(each.value.permissions.initiate_cpm_account_management_operations, false)
    specify_next_account_content               = try(each.value.permissions.specify_next_account_content, false)
    rename_accounts                            = try(each.value.permissions.rename_accounts, false)
    delete_accounts                            = try(each.value.permissions.delete_accounts, false)
    unlock_accounts                            = try(each.value.permissions.unlock_accounts, false)
    manage_safe                                = try(each.value.permissions.manage_safe, false)
    manage_safe_members                        = try(each.value.permissions.manage_safe_members, false)
    backup_safe                                = try(each.value.permissions.backup_safe, false)
    view_audit_log                             = try(each.value.permissions.view_audit_log, false)
    view_safe_members                          = try(each.value.permissions.view_safe_members, false)
    access_without_confirmation                = try(each.value.permissions.access_without_confirmation, false)
    create_folders                             = try(each.value.permissions.create_folders, false)
    delete_folders                             = try(each.value.permissions.delete_folders, false)
    move_accounts_and_folders                  = try(each.value.permissions.move_accounts_and_folders, false)
  }*/



resource "idsec_pcloud_account" "server_accounts" {
  for_each = toset(var.server_addresses)

  platform_id = var.server_platform_id
  username    = var.server_username
  address     = each.value
  secret      = var.server_secret
  safe_name   = idsec_pcloud_safe.m-server-local-admin.safe_name
  name        = "win-local-${each.value}"

  lifecycle {
    ignore_changes = [
      secret,
      name,
      account_id,
      created_time,
      category_modification_time,
      secret_type,
      platform_account_properties,
      status
    ]
  }
}
