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
# VPC Variables
# ===========================
variable "private_subnet_az" {
  description = "AWS identifier for the private subnet AZ"
  type        = string
  default     = "us-east-2b"
}

variable "public_subnet_az" {
  description = "AWS identifier for the public subnet AZ"
  type        = string
  default     = "us-east-2a"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for your public subnet"
  type        = string
  default     = "192.168.50.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for your private subnet"
  type        = string
  default     = "192.168.20.0/24"
}

variable "domain_name" {
  description = "Name of the domain to join connectors to"
  type        = string
}

variable "dc1_private_ip" {
  description = "Private IP of DC1 (used as DNS server IP)"
  type        = string
}

# ===========================
# Security Group Variables
# ===========================
variable "trusted_ips" {
  description = "Trusted public IPs"
  type        = list(string)
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
