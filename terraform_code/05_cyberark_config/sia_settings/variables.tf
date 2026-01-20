variable "region" {
  description = "AWS cloud region for the deployment"
  type        = string
  default     = "us-east-2"
}

variable "conjur_appliance_url" {
  description = "Conjur appliance URL"
  type        = string
}

variable "conjur_account" {
  description = "Conjur account name"
  type        = string
}

variable "conjur_api_key" {
  description = "Conjur API key"
  type        = string
  sensitive   = true
}

variable "conjur_login" {
  description = "Conjur login"
  type        = string
}

variable "conjur_identity_client_id_path" {
  description = "Conjur secret path for identity client ID"
  type        = string
}

variable "conjur_identity_client_secret_path" {
  description = "Conjur secret path for identity client secret"
  type        = string
}
