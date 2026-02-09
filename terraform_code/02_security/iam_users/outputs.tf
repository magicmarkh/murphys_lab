# ===========================
# IAM User Outputs
# ===========================
output "iam_user_name" {
  description = "Name of the IAM user"
  value       = aws_iam_user.this.name
}

output "iam_user_arn" {
  description = "ARN of the IAM user"
  value       = aws_iam_user.this.arn
}

output "access_key_ids" {
  description = "List of access key IDs for this user"
  value       = data.aws_iam_access_keys.existing.access_keys[*].access_key_id
}

output "access_key_count" {
  description = "Number of access keys"
  value       = length(data.aws_iam_access_keys.existing.access_keys)
}
