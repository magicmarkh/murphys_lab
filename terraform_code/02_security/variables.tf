# ===========================
# Common Variables
# ===========================
variable "asset_owner_name" {
  description = "Name of the human that the cloud team can contact with questions"
  type        = string
}

variable "region" {
  description = "AWS cloud region for the deployment"
  type        = string
  default     = "us-east-2"
}

variable "team_name" {
  description = "Cloud naming identifier"
  type        = string
  default     = "us-ent-east"
}

# ===========================
# Secrets Manager Variables
# ===========================
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

# ===========================
# IAM Role Variables
# ===========================
variable "CyberArkSecretsHubRoleARN" {
  description = "The Secrets Hub tenant role ARN which will be trusted by this role - get this from the cyberark tenant in secrets hub settings."
  type        = string
}

variable "cyberark_secret_arn" {
  description = "ARN of the identity service account. Used if retrieving the service account from ASM."
  type        = string
}
