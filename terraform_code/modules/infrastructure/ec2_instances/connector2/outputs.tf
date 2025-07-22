output "connector_2_local_admin_password" {
  value = random_password.local_admin_password.result
  sensitive = true
}