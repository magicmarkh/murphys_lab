# ===========================
# General Configuration
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

variable "iScheduler" {
  description = "iScheduler tag for automated shutdown"
  type        = string
  default     = "US_E_office"
}

# ===========================
# Instance Configuration
# ===========================
variable "hostname" {
  description = "Hostname for the Windows target instance"
  type        = string
  default     = "win-target-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.medium"
}

# ===========================
# Remote State Configuration
# ===========================
variable "state_bucket" {
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = "us-ent-east"
}

variable "state_region" {
  description = "AWS region for S3 state bucket"
  type        = string
  default     = "us-east-2"
}

variable "foundation_state_key" {
  description = "S3 key for foundation layer state"
  type        = string
  default     = "terraform/foundation.tfstate"
}

variable "security_state_key" {
  description = "S3 key for security layer state"
  type        = string
  default     = "terraform/security.tfstate"
}

# ===========================
# Domain Configuration
# ===========================
variable "domain_name" {
  description = "Active Directory domain name"
  type        = string
  default     = "murphyslab.local"
}

# ===========================
# CyberArk Configuration
# ===========================
variable "platform_id" {
  description = "CyberArk platform ID for Windows local admin accounts"
  type        = string
  default     = "M-Windows-Server-Local-Admin"
}

variable "safe_name" {
  description = "Name of the safe created in CyberArk"
  type = string
  default = "m-eph-windows-local"
}
variable "safe_description" {
  description = "Description for the CyberArk safe"
  type        = string
  default     = "Demo Windows Target Server - Local Administrator Account"
}

variable "safe_retention_days" {
  description = "Number of days to retain deleted accounts in the safe"
  type        = number
  default     = 0
}

# ===========================
# Conjur Configuration
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
}

variable "conjur_identity_client_id_path" {
  description = "Conjur secret path for Identity client ID"
  type        = string
  default     = "data/your/conjur/path"
}

variable "conjur_identity_client_secret_path" {
  description = "Conjur secret path for Identity client secret"
  type        = string
  default     = "data/your/conjur/path"
}

variable "conjur_domain_join_username_path" {
  description = "Conjur secret path for domain join username"
  type        = string
  default     = "data/your/conjur/path"
}

variable "conjur_domain_join_password_path" {
  description = "Conjur secret path for domain join password"
  type        = string
  default     = "data/your/conjur/path"
}

variable "conjur_aws_access_key_path" {
  description = "Conjur secret path for AWS Access Key ID"
  type        = string
  default     = "data/your/conjur/path"
}

variable "conjur_aws_secret_key_path" {
  description = "Conjur secret path for AWS Secret Access Key"
  type        = string
  default     = "data/your/conjur/path"
}
