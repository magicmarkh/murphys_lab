output "instance_profile_name" {
  description = "Name of the EC2 S3 instance profile"
  value       = aws_iam_instance_profile.ec2_s3_instance_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 S3 instance profile"
  value       = aws_iam_instance_profile.ec2_s3_instance_profile.arn
}

output "role_arn" {
  description = "ARN of the EC2 S3 IAM role"
  value       = aws_iam_role.ec2_s3_role.arn
}

output "role_name" {
  description = "Name of the EC2 S3 IAM role"
  value       = aws_iam_role.ec2_s3_role.name
}
