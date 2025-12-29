variable "vpc_id" {}
variable "private_subnet_id" {}
variable "team_name" {}
variable "asset_owner_name" {}
variable "windows_ami_id" {}
variable "iScheduler" {}
variable "windows_security_group_ids" {
  description = "List of security group IDs to attach to the instances"
  type        = list(string)
}
variable "connector_1_private_ip" {}
variable "sia_aws_connector_1_private_ip" {}


variable "windows_instance_type" {
  description = "instance type to be deployed"
  type = string
  default = "t3a.medium"
}
variable "key_name" {
  description = "The name of the AWS key pair to use for the instance"
}

