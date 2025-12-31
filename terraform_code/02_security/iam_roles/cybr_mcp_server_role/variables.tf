variable "role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = "cybr-mcp-server-role"
}

variable "instance_profile_name" {
  description = "Name of the instance profile"
  type        = string
  default     = "cybr-mcp-server-instance-profile"
}

variable "cyberark_secret_arn" {
  description = "ARN(s) of the CyberArk secrets in Secrets Manager"
  type        = list(string)
}