output "mysql_generated_password" {
  value     = module.mysql.mysql_generated_password
  sensitive = true
}

output "postgresql_generated_password" {
  value     = module.postgresql.postgresql_generated_password
  sensitive = true
}
/*
output "connector_2_local_admin_password" {
  value = module.connector2.connector_2_local_admin_password
  sensitive = true
}*/