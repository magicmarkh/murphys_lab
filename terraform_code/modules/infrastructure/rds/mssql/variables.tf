variable "asset_owner_name" {}
variable "iScheduler" {}

variable "identifier" {
  description = "The DB instance identifier"
  type        = string
  default     = "us-ent-east-mssql"
}

variable "instance_class" {
  description = "Instance type - db.t3.micro is cheapest for SQL Server Express"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "DB storage in GB - minimum 20GB for SQL Server Express"
  type        = number
  default     = 20
}

variable "username" {
  description = "Master username for SQL Server"
  type        = string
  default     = "admin"
}

variable "db_subnet_group_name" {
  description = "DB subnet group"
  type        = string
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "publicly_accessible" {
  description = "Whether the DB is publicly accessible"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "backup_retention" {
  description = "Backup retention period in days"
  type        = number
  default     = 1
}

variable "domain_auth_secret_arn" {
  description = "ARN of the secret in AWS Secrets Manager for joining the MSSQL instance to local Active Directory"
  type = string
}

variable "domain_dns_ips" {
  description = "List of DNS IP addresses for the domain"
  type        = list(string)
  default     = ["192.168.20.10", "192.168.20.10"]
}

variable "domain_ou" {
  description = "OU where the MSSQL DB is to be joined to"
  type        = string
}