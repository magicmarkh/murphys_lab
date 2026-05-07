variable "idsec_service_user" {
  description = "The service user email for the Identity Security provider"
  type        = string
  default     = ""
}

variable "idsec_service_token" {
  description = "The service token for the Identity Security provider"
  type        = string
  default     = ""
}

variable "organization_id" {
  description = "The unique identifier for the AWS Organization"
  type        = string
  default     = "o-1234567890"
}

variable "mgmt_acct" {
  description = "The 12 digit AWS Account ID of the management account in the organization"
  type        = string
  default     = ""
}

variable "organization_root_id" {
  description = "The unique identifier for the root of the AWS Organization"
  type        = string
  default     = "r-abcdefg1234"
}

variable "display_name" {
  description = "The display name for the CCE organization in CyberArk Identity Security"
  type        = string
  default     = "My AWS Organization"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}