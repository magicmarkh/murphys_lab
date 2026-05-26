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

# AWS Organization Targets
variable "aws_organization_targets" {
  type = list(object({
    role_id        = string
    workspace_id   = string
    #role_name      = string
    #workspace_name = string
    org_id         = string
      }))
  description = "List of AWS organization targets with role information"
}
