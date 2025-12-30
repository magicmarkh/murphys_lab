output "role_arn" {
  description = "ARN of the Secrets Hub onboarding role"
  value       = aws_iam_role.SecretsHubOnboardingRole.arn
}

output "role_name" {
  description = "Name of the Secrets Hub onboarding role"
  value       = aws_iam_role.SecretsHubOnboardingRole.name
}

output "policy_arn" {
  description = "ARN of the Secrets Hub onboarding policy"
  value       = aws_iam_policy.SecretsHubOnboardingPolicy.arn
}
