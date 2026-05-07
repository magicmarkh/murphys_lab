# ===========================
# CyberArk Identity Security Platform
# ===========================
variable "idsec_service_user" {
  description = "CyberArk Identity service user for idsec provider authentication"
  type        = string
  sensitive   = true
}

variable "idsec_service_token" {
  description = "CyberArk Identity service token for idsec provider authentication"
  type        = string
  sensitive   = true
}

# ===========================
# AWS Configuration
# ===========================
variable "aws_region" {
  description = "AWS region for provider configuration"
  type        = string
  default     = "us-east-2"
}

# ===========================
# AWS Organization Configuration
# ===========================
variable "organization_id" {
  description = "AWS Organization ID (e.g., o-1234567890)"
  type        = string
}

variable "management_account_id" {
  description = "AWS Management Account ID (12-digit)"
  type        = string
}

variable "organization_root_id" {
  description = "AWS Organization root ID (e.g., r-abcd)"
  type        = string
}

variable "display_name" {
  description = "Display name for the organization in CyberArk CCE"
  type        = string
  default     = "My Org"
}

# ===========================
# Service Feature Flags
# ===========================
variable "enable_sca" {
  description = "Enable Secure Cloud Access (SCA) service"
  type        = bool
  default     = true
}

variable "enable_sia" {
  description = "Enable Secure Infrastructure Access (SIA) service"
  type        = bool
  default     = false
}

variable "sca_sso_enable" {
  description = "Enable AWS IAM Identity Center (SSO) integration for SCA"
  type        = bool
  default     = false
}

variable "sca_sso_region" {
  description = "AWS region where IAM Identity Center is configured (required when sca_sso_enable = true)"
  type        = string
  default     = null
}
