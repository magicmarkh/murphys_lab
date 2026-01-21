resource "idsec_pcloud_safe" "m-domain-admins" {
  safe_name                = "m-domain-admins"
  description              = ""
  number_of_days_retention = 7

  lifecycle {
    prevent_destroy = true
  }
}

resource "idsec_pcloud_safe" "m-domain-server-admins" {
  safe_name                = "m-domain-server-admins"
  description              = ""
  number_of_days_retention = 7
}

resource "idsec_pcloud_safe" "m-domain-user" {
  safe_name                = "m-domain-user"
  description              = ""
  number_of_days_retention = 7
}
