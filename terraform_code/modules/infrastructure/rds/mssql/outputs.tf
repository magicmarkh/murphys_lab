output "mssql_generated_password" {
  value     = random_password.mssql_admin_password.result
  sensitive = true
}

output "mssql_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.mssql.endpoint
}

output "mssql_port" {
  description = "RDS instance port"
  value       = aws_db_instance.mssql.port
}

output "mssql_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.mssql.identifier
}