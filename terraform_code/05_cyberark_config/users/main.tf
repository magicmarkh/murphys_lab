resource "idsec_identity_user" "users" {
  for_each = var.users

  username                   = each.value.username
  display_name               = each.value.display_name
  email                      = each.value.email
  send_email_invite          = true
  force_password_change_next = true

  lifecycle {
    ignore_changes = [
      send_email_invite,
      force_password_change_next,
      suffix,
      user_id,
      last_login,
      mobile_number
    ]
  }
}
