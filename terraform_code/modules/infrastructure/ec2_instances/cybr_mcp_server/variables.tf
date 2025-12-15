variable "vpc_id" {}
variable "private_subnet_id" {}
variable "team_name" {}
variable "asset_owner_name" {}
variable "ami_id" {}
variable "iScheduler" {}
variable "vpc_security_group_ids" {}
variable "private_ip_address" {}
variable "region" {}
variable "cyberark_secret_arn" {}
variable "identity_tenant_id" {}
variable "platform_tenant_name" {}
variable "workspace_id" {}
variable "workspace_type" {}
variable "mcp_server_hostname" {}
variable "ec2_asm_instance_profile_name" {}
variable "username_domain" {}

variable "instance_type" {
  description = "instance type to be deployed"
  type = string
  default = "t3a.medium"
}
variable "key_name" {
  description = "The name of the AWS key pair to use for the instance"
}