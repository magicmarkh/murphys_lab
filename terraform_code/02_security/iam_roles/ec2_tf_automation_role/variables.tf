variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket to grant access to"
  type        = string
}

variable "ec2_tf_automation_role_name" {
  description = "Name of the IAM role for EC2 Terraform automation"
  type        = string
  default     = "ec2-tf-automation-role"
}
