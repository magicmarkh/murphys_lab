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
  default     = "db.t3.micro"
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