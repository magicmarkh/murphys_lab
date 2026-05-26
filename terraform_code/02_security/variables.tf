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

# ===========================
# Remote State Variables
# ===========================
variable "state_bucket" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = "my-terraform-state-bucket"
}

variable "foundation_state_key" {
  description = "S3 key for foundation Terraform state"
  type        = string
  default     = "terraform/foundation.tfstate"
}

variable "state_region" {
  description = "AWS region for Terraform state bucket"
  type        = string
  default     = "us-east-1"
}

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
# IAM User Variables
# ===========================
variable "automation_iam_username" {
  description = "IAM username for the automation user"
  type        = string
  default     = "us-ent-east-automation"
}

variable "automation_iam_user_path" {
  description = "Path for the automation IAM user"
  type        = string
  default     = "/"
}
