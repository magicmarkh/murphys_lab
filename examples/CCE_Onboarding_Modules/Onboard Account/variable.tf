variable "idsec_service_user" {
  description = "The service user upn for the Identity Security provider (e.g., svcacct@cyberark.cloud.12345)"
  type        = string
  default     = ""
}

variable "idsec_service_token" {
  description = "The service token for the Identity Security provider"
  type        = string
  default     = ""
}

variable "org_onboarding_id" {
  description = "The AWS Organization Onboarding Id from the CCE create org output"
  type        = string
  default     = ""
}

variable "services" {
  description = "List of services to enable for this account (e.g., [\"sia\", \"sca\"])"
  type        = list(string)
  default     = ["sia", "sca"]
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}