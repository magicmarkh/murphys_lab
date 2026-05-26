variable "region" {
  description = "AWS cloud region for the deployment"
  type        = string
  default     = "us-east-2"
}

variable "conjur_appliance_url" {
  description = "Conjur appliance URL"
  type        = string
  default     = "https://murphyslab.secretsmgr.cyberark.cloud/api"
}

variable "conjur_account" {
  description = "Conjur account name"
  type        = string
  default     = "conjur"
}

variable "conjur_api_key" {
  description = "Conjur API key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "conjur_login" {
  description = "Conjur login"
  type        = string
  default     = "host/data/murphys-tf"
}

variable "conjur_identity_client_id_path" {
  description = "Conjur secret path for identity client ID"
  type        = string
}

variable "conjur_identity_client_secret_path" {
  description = "Conjur secret path for identity client secret"
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
