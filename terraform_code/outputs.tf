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
output "mssql_generated_password" {
  value     = module.mssql.mssql_generated_password
  sensitive = true
}

output "mssql_endpoint" {
  value = module.mssql.mssql_endpoint
}