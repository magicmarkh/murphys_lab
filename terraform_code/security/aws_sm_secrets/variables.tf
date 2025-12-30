variable "domain_join_username" {
  description = "Domain join username (e.g., CORP\\joinuser)"
  type        = string
}

variable "domain_join_password" {
  description = "Domain join password"
  type        = string
  sensitive   = true
}

variable "domain_join_secret_name" {
  description = "Secrets Manager secret name"
  type        = string
}

variable "create_secret_version" {
  description = "should we update the actual secret value in AWS SM"
  type = bool
  default = false
}