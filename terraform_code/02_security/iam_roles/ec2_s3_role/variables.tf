variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket to grant access to"
  type        = string
}

variable "ec2_s3_role_name" {
  description = "Name of the IAM role for EC2 S3 access"
  type        = string
  default     = "ec2-s3-access-role"
}
