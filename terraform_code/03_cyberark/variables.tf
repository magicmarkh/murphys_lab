# ===========================
# Common Variables
# ===========================
variable "region" {
  description = "AWS cloud region for the deployment"
  type        = string
  default     = "us-east-2"
}

# ===========================
# CyberArk Identity Variables
# ===========================
variable "identity_client_id" {
  description = "CyberArk Identity OAuth client ID (service user)"
  type        = string
  sensitive   = true
}

variable "identity_client_secret" {
  description = "CyberArk Identity OAuth client secret"
  type        = string
  sensitive   = true
}

variable "identity_tenant_url" {
  description = "Full CyberArk Identity tenant URL (e.g., https://abc123.id.cyberark.cloud)"
  type        = string
}

# ===========================
# Connector Manager Variables
# ===========================
variable "connector_network_name" {
  description = "Name of the connector network"
  type        = string
}

variable "connector_network_description" {
  description = "Description of the connector network"
  type        = string
  default     = ""
}

variable "connector_pool_name1" {
  description = "Name of the connector pool"
  type        = string
}

variable "connector_pool_description" {
  description = "Description of the connector pool"
  type        = string
  default     = ""
}

variable "connector_pool_identifiers" {
  description = "List of FQDNs for the connector pool"
  type        = list(string)
  default     = []
}

variable "connector_manager_tags" {
  description = "Tags to apply to connector manager resources"
  type = map(object({
    key   = string
    value = string
  }))
  default = {}
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

# ===========================