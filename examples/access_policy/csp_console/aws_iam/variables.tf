# ===========================
# Conjur Variables
# ===========================
variable "conjur_appliance_url" {
  type = string
  description = "conjur api url"
}
variable "conjur_account" {
  type = string
  description = "conjur account name"
}
variable "conjur_api_key" {
  type      = string
  description = "conjur api key"
  sensitive = true
  default     = ""
}
variable "conjur_login" {
  type = string
  description = "conjur login name"
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
# Policy Variables
# ===========================
variable "policy_name" {
  type = string
  description = "Name of the policy to be created"
}

variable "policy_description" {
  type = string
  description = "Description of the policy to be created"
}

variable "location_type" {
  type = string
  description = "CSP location e.g. AWS, AZURE, GCP"
}

variable "time_zone" {
  type        = string
  description = "IANA Country value eg. America/New_York, America/Chicago, Asia/Tokyo.."
  default     = "America/New_York"
}

variable "from_time" {
  description = "The date the policy becomes active | pattern: yyyy-MM-ddTHH:mm:ss"
  type        = string
  default     = null
  validation {
    condition     = var.from_time == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$", var.from_time))
    error_message = "fromTime must be null or match the pattern yyyy-MM-ddTHH:mm:ss (e.g., 2025-07-05T12:34:56)."
  }
}
variable "to_time" {
  description = "The date the policy expires. | pattern: yyyy-MM-ddTHH:mm:ss"
  type        = string
  default     = null
  validation {
    condition     = var.to_time == null || can(regex("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}$", var.to_time))
    error_message = "to_time must be null or match the pattern yyyy-MM-ddTHH:mm:ss (e.g., 2026-07-05T12:34:56)."
  }
}

# Principals
variable "principals" {
  type = list(object({
    #id   = string
    source_directory_id = string
    name = string
    type = string
  }))
  description = "List of principals (users/groups) who can access the policy"
}

# Conditions - Access Window
variable "access_window_days" {
  type        = list(number)
  description = "Days of the week (1=Monday, 7=Sunday)"
  default     = [1, 2, 3, 4, 5]
}

variable "access_window_from_hour" {
  type        = string
  description = "Start time for access window (HH:MM:SS format)"
  default     = "09:00:00"
}

variable "access_window_to_hour" {
  type        = string
  description = "End time for access window (HH:MM:SS format)"
  default     = "17:00:00"
}

variable "max_session_duration" {
  type        = number
  description = "Maximum session duration in hours"
  default     = 1
}

# AWS Account Targets
variable "aws_account_targets" {
  type = list(object({
    role_id        = string
    workspace_id   = string
    role_name      = string
    workspace_name = string
  }))
  description = "List of AWS account targets with role information"
}
