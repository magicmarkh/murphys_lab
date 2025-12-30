variable "Policy" {
  description = "Meaningful policy name"
  type        = string
  default = "SecretsHubInstallPolicy"
}

variable "CyberArkSecretsHubRoleARN" {
  description = "The Secrets Hub tenant role ARN which will be trusted by this role - get this from the cyberark tenant in secrets hub settings."
  type        = string
}

variable "SecretsManagerRegion" {
  description = "The AWS Secrets Manager Account region that the Secrets Hub will have access to"
  type        = string
}

variable "AllowSecretExtendedAccess" {
  description = "Allow Secrets Hub to retrieve secret values"
  type        = bool
  default     = true
}