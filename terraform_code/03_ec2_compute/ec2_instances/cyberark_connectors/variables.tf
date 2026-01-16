variable "vpc_id" {}
variable "private_subnet_id" {}
variable "team_name" {}
variable "asset_owner_name" {}
variable "windows_ami_id" {}
variable "iScheduler" {}
variable "domain_name" {}
variable "connector_pool_id" {
  description = "CyberArk connector manager pool ID"
  type        = string
}

variable "windows_security_group_ids" {
  description = "List of security group IDs to attach to the instances"
  type        = list(string)
}
variable "connector_1_private_ip" {}
variable "sia_aws_connector_1_private_ip" {}


variable "windows_instance_type" {
  description = "instance type to be deployed"
  type        = string
  default     = "t3a.medium"
}
variable "key_name" {
  description = "The name of the AWS key pair to use for the instance"
}

# ===========================
# Linux Connector Variables
# ===========================
variable "linux_ami_id" {
  description = "AMI ID for Linux connector instance"
  type        = string
}

variable "linux_ami_id_instance_type" {
  description = "Instance type for Linux connector"
  type        = string
  default     = "t3a.medium"
}

variable "linux_security_group_ids" {
  description = "Security group ID for Linux connector"
  type        = string
}

variable "sia_linux_private_ip" {
  description = "Private IP address for SIA Linux connector"
  type        = string
}

#variable "instance_profile_name" {
#  description = "IAM instance profile name for ASM access"
#  type        = string#
#}

variable "hostname" {
  description = "Hostname for the Linux connector instance"
  type        = string
  default     = "us-ent-east-sia-aws-connector-2"
}

variable "private_key_path" {
  description = "Path to the private key file for SSH access"
  type        = string
}

# ===========================
# Conjur Secret Variables
# ===========================
variable "domain_join_username" {
  description = "Domain join username from Conjur"
  type        = string
  sensitive   = true
}

variable "domain_join_password" {
  description = "Domain join password from Conjur"
  type        = string
  sensitive   = true
}
