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
  default     = "demo-win-target"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3a.medium"
}

# ===========================
# Network Configuration
# ===========================
variable "vpc_name" {
  description = "Name tag of the VPC to deploy into"
  type        = string
  default     = "us-ent-east-vpc"
}

variable "subnet_name" {
  description = "Name tag of the subnet to deploy into"
  type        = string
  default     = "private-flat"
}

variable "rdp_sg_name" {
  description = "Name of the RDP security group"
  type        = string
  default     = "rdp_internal_flat_sg"
}

variable "winrm_sg_name" {
  description = "Name of the WinRM security group"
  type        = string
  default     = "winrm_internal_flat_sg"
}

variable "sia_windows_target_sg_name" {
  description = "Name of the SIA Windows target security group"
  type        = string
  default     = "sia_windows_target_sg"
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

variable "safe_description" {
  description = "Description for the CyberArk safe"
  type        = string
  default     = "Demo Windows Target Server - Local Administrator Account"
}

variable "safe_retention_days" {
  description = "Number of days to retain deleted accounts in the safe"
  type        = number
  default     = 7
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
  default     = "data/vault/m-priv-svc-accts/svc_tfautomation/username"
}

variable "conjur_identity_client_secret_path" {
  description = "Conjur secret path for Identity client secret"
  type        = string
  default     = "data/vault/m-priv-svc-accts/svc_tfautomation/password"
}

variable "conjur_domain_join_username_path" {
  description = "Conjur secret path for domain join username"
  type        = string
  default     = "data/vault/m-priv-svc-accts/murphys-lab-domain-joiner/username"
}

variable "conjur_domain_join_password_path" {
  description = "Conjur secret path for domain join password"
  type        = string
  default     = "data/vault/m-priv-svc-accts/murphys-lab-domain-joiner/password"
}

variable "conjur_aws_access_key_path" {
  description = "Conjur secret path for AWS Access Key ID"
  type        = string
  default     = "data/vault/m-conjur-automation/us-ent-east-automation/AWSAccessKeyID"
}

variable "conjur_aws_secret_key_path" {
  description = "Conjur secret path for AWS Secret Access Key"
  type        = string
  default     = "data/vault/m-conjur-automation/us-ent-east-automation/password"
}
