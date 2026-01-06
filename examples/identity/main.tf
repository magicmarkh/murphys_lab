resource "random_password" "user_password" {
  for_each = var.users

  length      = 16
  special     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

resource "idsec_identity_role" "main" {
  role_name   = var.role_name
  description = var.role_description
}

resource "idsec_identity_user" "users" {
  for_each = var.users

  username      = each.value.username
  display_name  = each.value.display_name
  email         = each.value.email
  password      = random_password.user_password[each.key].result
  mobile_number = each.value.mobile_number
}

resource "idsec_identity_role_member" "role_members" {
  for_each = var.users

  role_id     = idsec_identity_role.main.role_id
  member_name = idsec_identity_user.users[each.key].username
  member_type = "USER"
}
