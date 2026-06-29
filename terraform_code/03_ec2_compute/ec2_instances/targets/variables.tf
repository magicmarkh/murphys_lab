variable "vpc_id" {}
variable "private_subnet_id" {}
variable "team_name" {}
variable "asset_owner_name" {}
variable "linux_ami_id" {}
variable "windows_ami_id" {}
variable "iScheduler" {}
variable "linux_security_group_ids" {}
variable "windows_security_group_ids" {}
variable "windows_target_1_private_ip" {}
variable "linux_target_1_private_ip" {}
variable "region" {}
variable "identity_tenant_id" {}
variable "platform_tenant_name" {}
variable "workspace_id" {}
variable "workspace_type" {}
variable "linux_target_1_hostname" {}
variable "identity_client_id" {
  description = "CyberArk Identity client ID (username) for OAuth authentication"
  type        = string
  sensitive   = true
}

variable "identity_client_secret" {
  description = "CyberArk Identity client secret (password) for OAuth authentication"
  type        = string
  sensitive   = true
}
variable "linux_instance_type" {
  description = "instance type to be deployed"
  type        = string
  default     = "t3a.medium"
}

variable "windows_instance_type" {
  description = "instance type to be deployed"
  type        = string
  default     = "t3a.large"
}
variable "key_name" {
  description = "The name of the AWS key pair to use for the instance"
}

variable "ec2_tf_automation_instance_profile_name" {
  description = "Name of the IAM instance profile for Terraform automation"
  type        = string
}
