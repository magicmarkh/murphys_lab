variable "vpc_id" {}
variable "private_subnet_id" {}
variable "team_name" {}
variable "asset_owner_name" {}
variable "windows_ami_id" {}
variable "iScheduler" {}
variable "windows_security_group_ids" {}
variable "private_ip" {
  description = "private IP of the connector to be deployed"
  type = string
}
variable "region" {
  description = "cloud region the instance is deployed to"
  type = string
}
variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type = string
}
variable "domain_name" {
  description = "name of the domain the system will be joined to"
  type = string
}
variable "domain_join_secret_arn" {
  description = "ARN of the ASM secret for the domain join service account"
  type = string
}
variable "identity_secret_arn" {
  description = "ARN of the ASM secret for the CyberArk Identity service account"
  type = string
}
variable "connector_pool_name" {
  description = "name of the connector pool to join the connector to"
  type = string
}

variable "windows_instance_type" {
  description = "instance type to be deployed"
  type = string
  default = "t3a.medium"
}
variable "key_name" {
  description = "The name of the AWS key pair to use for the instance"
}

variable "hostname" {
  description = "hostname of the system"
  type = string
}

variable "identity_tenant_id" {
  description = "tenant id for identity"
  type = string
}

variable "platform_tenant_name" {
  description = "platform tenant name"
  type = string
}