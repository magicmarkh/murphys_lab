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
/*
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
*/

# ===========================
# Server Accounts Variables
# ===========================
variable "server_addresses" {
  type        = list(string)
  description = "List of server addresses/hostnames to create accounts for"
  default     = []
}

variable "server_username" {
  type        = string
  description = "Username for server local admin accounts"
  default     = "Administrator"
}

variable "server_platform_id" {
  type        = string
  description = "Platform ID for server accounts"
  default     = "M-Windows-Server-Local-Admin"
}

variable "server_secret" {
  type        = string
  description = "Secret/password for server accounts"
  default     = "dummy!@#$1234"
  sensitive   = true
}