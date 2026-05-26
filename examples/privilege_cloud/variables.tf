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
  default     = ""
}
variable "conjur_login" {
  type = string
  description = "conjur login name"
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

# ===========================
# Privilege Cloud Safe Variables
# ===========================
variable "safe_name" {
  type        = string
  description = "Name of the Privilege Cloud safe"
}

variable "safe_description" {
  type        = string
  description = "Description of the safe"
  default     = ""
}

variable "managing_cpm" {
  type        = string
  description = "Name of the CPM managing the safe"
  default     = "PasswordManager"
}

variable "number_of_days_retention" {
  type        = number
  description = "Number of days to retain safe data"
  default     = 7
}

# ===========================
# Safe Member Variables
# ===========================
variable "safe_members" {
  type = map(object({
    member_name                = string
    member_type                = string
    search_in                  = optional(string)
    membership_expiration_date = optional(number)
    permission_set             = string
   /* permissions = object({
      use_accounts                               = optional(bool)
      retrieve_accounts                          = optional(bool)
      list_accounts                              = optional(bool)
      add_accounts                               = optional(bool)
      update_account_content                     = optional(bool)
      update_account_properties                  = optional(bool)
      initiate_cpm_account_management_operations = optional(bool)
      specify_next_account_content               = optional(bool)
      rename_accounts                            = optional(bool)
      delete_accounts                            = optional(bool)
      unlock_accounts                            = optional(bool)
      manage_safe                                = optional(bool)
      manage_safe_members                        = optional(bool)
      backup_safe                                = optional(bool)
      view_audit_log                             = optional(bool)
      view_safe_members                          = optional(bool)
      access_without_confirmation                = optional(bool)
      create_folders                             = optional(bool)
      delete_folders                             = optional(bool)
      move_accounts_and_folders                  = optional(bool)
    })*/
  }))
  description = "Map of members to add to the safe with their permissions"
  default     = {}
}

# ===========================
# Privilege Cloud Account Variables
# ===========================
variable "account_name" {
  type        = string
  description = "Name of the Privilege Cloud account"
}

variable "platform_id" {
  type        = string
  description = "Platform ID for the account (e.g., WinDesktopLocal, UnixSSH, etc.)"
}

variable "username" {
  type        = string
  description = "Username for the privileged account"
}

variable "address" {
  type        = string
  description = "Address/hostname of the target system"
}

variable "secret" {
  type        = string
  description = "Secret/password for the privileged account"
  sensitive   = true
}
