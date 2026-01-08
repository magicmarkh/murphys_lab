# =====================================================================
# DB SUBNET GROUP OUTPUTS
# =====================================================================
output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = module.db_subnet_group.db_subnet_group_name
}

# Commented out - RDS modules don't export endpoint outputs yet
# # =====================================================================
# # RDS DATABASE OUTPUTS
# # =====================================================================
# output "mysql_endpoint" {
#   description = "MySQL database endpoint"
#   value       = module.mysql.endpoint
# }

# output "postgresql_endpoint" {
#   description = "PostgreSQL database endpoint"
#   value       = module.postgresql.endpoint
# }

# output "mssql_endpoint" {
#   description = "MSSQL database endpoint"
#   value       = module.mssql.endpoint
# }
