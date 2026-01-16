variable "asset_owner_name" {
  description = "Name of the human that the cloud team can contact with questions"
  type        = string
}

variable "region" {
  description = "AWS cloud region for the deployment"
  default     = "us-east-2"
  type        = string
}

variable "team_name" {
  description = "cloud naming identifier"
  default     = "us-ent-east"
  type        = string
}

variable "amzn_linux_ami_id" {
  description = "ami id for amazon linux ec2 - defaults to latest Amazon Linux 2023"
  type        = string
  default     = null
}

variable "amzn_windows_server_ami_id" {
  description = "ami id for amazon windows ec2 - defaults to latest Windows Server 2022"
  type        = string
  default     = null
}

variable "iScheduler" {
  description = "use if the system should be shutdown nightly"
  type        = string
  default     = "US_E_office"
}

variable "dc1_private_ip" {
  description = "private ip of dc1"
  type        = string
}

variable "linux_target_1_private_ip" {
  description = "private ip of linux target 1"
  type        = string
}

variable "windows_target_1_private_ip" {
  description = "private ip of windows target 1"
  type        = string
}

variable "connector_1_private_ip" {
  description = "private ip of connector 1"
  type        = string
}

variable "sia_aws_connector_1_private_ip" {
  description = "private ip of sia aws connector 1"
  type        = string
}

variable "sia_aws_connector_2_private_ip" {
  description = "private ip of sia aws connector 2"
  type        = string
}

variable "connector_pool_name" {
  description = "Name of the connector pool you're adding the connector to"
  type        = string
}

variable "identity_tenant_id" {
  description = "your cyberark tenant id. Example: 'https://abc123.id.cyberark.cloud' woud be abc123"
  type        = string
}

variable "platform_tenant_name" {
  description = "name of your cyberark tenant. Example: 'https://acme.cyberark.cloud' would be acme"
  type        = string
}

variable "workspace_type" {
  description = "CSP identifier. AWS, Azure, or GCP"
  type        = string
  default     = "AWS"
}

variable "linux_target_1_hostname" {
  description = "name of the target demo system for linux"
  type        = string
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

variable "conjur_identity_client_id_path" {
  description = "Conjur secret path for Identity client ID"
  type        = string
  default     = ""
}

variable "conjur_identity_client_secret_path" {
  description = "Conjur secret path for Identity client secret"
  type        = string
  default     = ""
}

variable "conjur_domain_join_username_path" {
  description = "Conjur secret path for domain join username"
  type        = string
  default     = ""
}

variable "conjur_domain_join_password_path" {
  description = "Conjur secret path for domain join password"
  type        = string
  default     = ""
}

variable "conjur_identity_username_path" {
  description = "Conjur secret path for identity username"
  type        = string
  default     = ""
}

variable "conjur_identity_password_path" {
  description = "Conjur secret path for identity password"
  type        = string
  default     = ""
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

variable "security_state_key" {
  description = "S3 key for security Terraform state"
  type        = string
  default     = "terraform/security.tfstate"
}

variable "cyberark_connector_pools_state_key" {
  description = "S3 key for CyberArk connector pools Terraform state"
  type        = string
  default     = "terraform/cyberark_connector_pools.tfstate"
}

variable "state_region" {
  description = "AWS region for Terraform state bucket"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "domain to join the Windows connector to"
  type        = string
  default     = ""
}
