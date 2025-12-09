variable "auth_url" {
  description = "Oauth2  URL for authentication"
  type        = string
}

variable "tenant_domain_name" {
  description = "Tenant sub domain name"
  type        = string
}

variable "platform_domain_name" {
  description = "platform domain name"
  type        = string
  default     = "cyberark.cloud"
}

variable "username" {
  description = "SCA service user username"
  type        = string
  sensitive   = true
}

variable "password" {
  description = "SCA service user password"
  type        = string
  sensitive   = true
}

variable "csp" {
  description = "The name of the cloud provider ('AWS','GCP','AZURE')"
  type        = string
}

variable "root_organization_id" {
  description = "Root Organization id"
  type        = string
}

variable "workspace_id" {
  description = "Workspace id"
  type        = string
}

variable "new_account" {
  description = "Is this new account"
  type        = bool
}

variable "roles" {
  description = "List of CloudRoles"
  type        = list(map(string))

}

variable "identities" {
  description = "List of Identities"
  type        = list(map(string))
}

variable "start_date" {
  description = "Start date of the policy in ISO 8601 format"
  type        = string
  default     = null
}

variable "end_date" {
  description = "End date of the policy in ISO 8601 format"
  type        = string
  default     = null
}

variable "access_rules" {
  description = "Access rules for the policy"
  type        = object({
    days                 = list(string)
    from_time            = optional(string, null)
    to_time              = optional(string, null)
    max_session_duration = number
    time_zone            = string
  })
  default = null
}

variable "policy_name" {
  description = "name of the policy"
  type        = string
  default     = "terraform-aws-iam-example"
}

variable "policy_description"{
  description = "policy description"
  type        = string
  default     = "Created via Terraform"
}