# ===========================
# Conjur Variables
# ===========================
variable "conjur_appliance_url" {
  description = "URL of the Conjur appliance"
  type        = string
  default     = "https://murphyslab.secretsmgr.cyberark.cloud/api"
}

variable "conjur_account" {
  description = "Conjur account name"
  type        = string
  default     = "conjur"
}

variable "conjur_login" {
  description = "Conjur login name"
  type        = string
  default     = "host/data/murphys-tf"
}

variable "conjur_api_key" {
  description = "Conjur API key for the specified login"
  type        = string
  sensitive   = true
  default     = ""
}

variable "conjur_identity_client_id_path" {
  description = "Conjur secret path for Identity client ID"
  type        = string
}

variable "conjur_identity_client_secret_path" {
  description = "Conjur secret path for Identity client secret"
  type        = string
}

variable "conjur_aws_access_key_path" {
  description = "Conjur secret path for AWS Access Key ID"
  type        = string
  default     = ""
}

variable "conjur_aws_secret_key_path" {
  description = "Conjur secret path for AWS Secret Access Key"
  type        = string
  default     = ""
}

variable "conjur_authn_type" {
  description = "Conjur auth method: 'api' for API key (laptop), 'iam' for AWS IAM (EC2)"
  type        = string
  default     = "api"
  validation {
    condition     = contains(["api", "iam"], var.conjur_authn_type)
    error_message = "conjur_authn_type must be 'api' or 'iam'."
  }
}

variable "conjur_service_id" {
  description = "Conjur authn-iam service ID (required when conjur_authn_type = 'iam')"
  type        = string
  default     = ""
}

variable "conjur_host_id" {
  description = "Conjur host identity for IAM auth (required when conjur_authn_type = 'iam')"
  type        = string
  default     = ""
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
