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
# Privilege Cloud Account Variables
# ===========================
variable "accounts" {
  type = map(object({
    name                         = string
    address                      = string
    username                     = string
    platform_id                  = string
    secret_type                  = string
    secret                       = string
    automatic_management_enabled = optional(bool)
  }))
  description = "Map of accounts to create in the safe"
  default     = {}
}

# ===========================
# Safe Member Variables
# ===========================
variable "safe_members" {
  type = map(object({
    member_name                = string
    member_type                = string
    search_in                  = optional(string)
    membership_expiration_date = optional(string)
    permissions = object({
      use_accounts                                   = optional(bool)
      retrieve_accounts                              = optional(bool)
      list_accounts                                  = optional(bool)
      add_accounts                                   = optional(bool)
      update_account_content                         = optional(bool)
      update_account_properties                      = optional(bool)
      initiate_cpm_account_management_operations     = optional(bool)
      specify_next_account_content                   = optional(bool)
      rename_accounts                                = optional(bool)
      delete_accounts                                = optional(bool)
      unlock_accounts                                = optional(bool)
      manage_safe                                    = optional(bool)
      manage_safe_members                            = optional(bool)
      backup_safe                                    = optional(bool)
      view_audit_log                                 = optional(bool)
      view_safe_members                              = optional(bool)
      access_without_confirmation                    = optional(bool)
      create_folders                                 = optional(bool)
      delete_folders                                 = optional(bool)
      move_accounts_and_folders                      = optional(bool)
    })
  }))
  description = "Map of members to add to the safe with their permissions"
  default     = {}
}
