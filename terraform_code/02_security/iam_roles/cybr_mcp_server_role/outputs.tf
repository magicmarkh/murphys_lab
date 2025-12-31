output "role_arn" {
  description = "ARN of the CyberArk MCP Server IAM role"
  value       = aws_iam_role.cybr_mcp_server_role.arn
}

output "role_name" {
  description = "Name of the CyberArk MCP Server IAM role"
  value       = aws_iam_role.cybr_mcp_server_role.name
}

output "instance_profile_name" {
  description = "Name of the CyberArk MCP Server instance profile"
  value       = aws_iam_instance_profile.cybr_mcp_server_instance_profile.name
}

output "instance_profile_arn" {
  description = "ARN of the CyberArk MCP Server instance profile"
  value       = aws_iam_instance_profile.cybr_mcp_server_instance_profile.arn
}