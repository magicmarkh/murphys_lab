resource "idsec_pcloud_safe" "m-database-root" {
  safe_name                = "m-database-root"
  description              = ""
  number_of_days_retention = 7
}
/* waiting on safe permissions bug to be resolved
resource "idsec_pcloud_safe_member" "example_safe_members" {
  for_each = toset(var.example_members)

  safe_id        = idsec_pcloud_safe.example_safe.safe_id
  member_name    = each.value
  member_type    = "User"
  permission_set = "connect_only"
}*/