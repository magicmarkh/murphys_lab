variable "cyberark_secret_arn" {}
variable "ec2_aws_role_name" {
  description = "name of the role to be created. The role allows retrieval of the identity secret from ASM"
  type = string
  default = "us-ent-east-ec2-asm-role"
}
