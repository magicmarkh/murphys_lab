variable "vpc_id" {}
variable "private_subnet_id" {}
variable "team_name" {}
variable "asset_owner_name" {}
variable "windows_ami_id" {
  default = "ami-06fbbb433da1a5bf7"
  type = string
}
variable "iScheduler" {}
variable "security_group_ids" {}
variable "key_name" {}
variable "private_ip" {}
variable "windows_instance_type" {
  description = "instance type to be deployed"
  type = string
  default = "t3a.medium"
}