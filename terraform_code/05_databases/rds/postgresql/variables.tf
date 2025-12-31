variable "team_name" {}
variable "asset_owner_name" {}
variable "iScheduler" {}
variable "db_subnet_group_name" {}

variable "postgresql_db_name" {
  type        = string
  default     = "music"
}

variable "postgresql_username" {
  type        = string
  default     = "admin"
}

variable "instance_class" {
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  type        = number
  default     = 10
}

variable "username" {
  description = "Master username"
  type        = string
  default = "db_admin"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default = "music"
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
  type = bool
  default = false
}

variable "backup_retention" {
  type = number
  default = 1
}