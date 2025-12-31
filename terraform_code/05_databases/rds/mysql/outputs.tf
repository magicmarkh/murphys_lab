output "mysql_generated_password" {
  value     = random_password.mysql_admin_password.result
  sensitive = true
}