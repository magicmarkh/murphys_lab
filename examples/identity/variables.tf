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
}
variable "conjur_login" {
  type = string
  description = "conjur login name"
}

# ===========================
# Identity Role Variables
# ===========================
variable "role_name" {
  type        = string
  description = "Name of the identity role"
}

variable "role_description" {
  type        = string
  description = "Description of the identity role"
  default     = ""
}

# ===========================
# Identity User Variables
# ===========================
variable "users" {
  type = map(object({
    username      = string
    display_name  = string
    email         = string
    mobile_number = string
  }))
  description = "Map of users to create and add to the role"
}