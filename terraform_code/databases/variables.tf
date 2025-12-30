variable "asset_owner_name" {
  description = "Name of the human that the cloud team can contact with questions"
  type        = string
}

variable "region" {
  description = "AWS cloud region for the deployment"
  default     = "us-east-2"
  type        = string
}

variable "team_name" {
  description = "cloud naming identifier"
  default     = "us-ent-east"
  type        = string
}

variable "iScheduler" {
  description = "use if the system should be shutdown nightly"
  type        = string
  default     = "US_E_office"
}

variable "mssql_domain_join_arn" {
  description = "arn for mssql service account"
  type        = string
  default     = null
}

variable "mssql_domain_ou" {
  description = "Organizational Unit (OU) in AD for RDS MSSQL (optional)"
  type        = string
  default     = null
}
