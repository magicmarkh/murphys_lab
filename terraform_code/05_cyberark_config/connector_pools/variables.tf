# ===========================
# Common Variables
# ===========================
variable "region" {
  description = "AWS cloud region for the deployment"
  type        = string
  default     = "us-east-2"
}

# ===========================
# Conjur Variables
# ===========================
variable "conjur_appliance_url" {
  description = "URL of the Conjur appliance"
  type        = string
}

variable "conjur_account" {
  description = "Conjur account name"
  type        = string
}

variable "conjur_login" {
  description = "Conjur login name"
  type        = string
}

variable "conjur_api_key" {
  description = "Conjur API key for the specified login"
  type        = string
  sensitive   = true
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

# ===========================
# Connector Manager Variables
# ===========================
variable "networks" {
  description = "List of connector network names to create"
  type        = list(string)
}

variable "pool_name" {
  description = "Name of the connector manager pool"
  type        = string
}

variable "pool_description" {
  description = "Description of the connector manager pool"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to the connector manager pool"
  type = map(object({
    key   = string
    value = string
  }))
  default = {}
}

variable "ad_domain_name" {
  description = "name of the AD Domain to integrate"
  type = string
  default = "acme.com"
}

variable "rds_domain_name" {
  description = "domain for rds instances"
  type = string
  default = "abc123.us-east-1.rds.amazonaws.com"
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