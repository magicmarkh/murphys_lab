output "postgresql_generated_password" {
  value     = random_password.postgresql_admin_password.result
  sensitive = true
}