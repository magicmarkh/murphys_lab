# ===========================
# Secrets Manager Outputs
# ===========================
/*output "domain_join_secret_arn" {
  description = "ARN of the domain join Secrets Manager secret"
  value       = module.aws_sm_secrets.secret_arn
}*/

# ===========================
# IAM Role Outputs
# ===========================
output "ec2_asm_instance_profile_name" {
  description = "Name of the EC2 ASM instance profile"
  value       = module.ec2_asm_role.us_ent_east_ec2_asm_instance_profile_name
}

output "cybr_mcp_server_instance_profile_name" {
  description = "Name of the CyberArk MCP Server instance profile"
  value       = module.cybr_mcp_server_role.instance_profile_name
}

output "cybr_mcp_server_instance_profile_arn" {
  description = "ARN of the CyberArk MCP Server instance profile"
  value       = module.cybr_mcp_server_role.instance_profile_arn
}

output "cybr_mcp_server_role_arn" {
  description = "ARN of the CyberArk MCP Server IAM role"
  value       = module.cybr_mcp_server_role.role_arn
}

output "cybr_mcp_server_role_name" {
  description = "Name of the CyberArk MCP Server IAM role"
  value       = module.cybr_mcp_server_role.role_name
}

output "secrets_hub_onboarding_role_arn" {
  description = "ARN of the Secrets Hub onboarding role"
  value       = module.secrets_hub_onboarding_role.role_arn
  sensitive   = true
}

# =====================================================================
# IAM User Outputs
# =====================================================================
output "automation_user_name" {
  description = "Name of the automation IAM user"
  value       = module.us_ent_east_automation_user.iam_user_name
}

output "automation_user_arn" {
  description = "ARN of the automation IAM user"
  value       = module.us_ent_east_automation_user.iam_user_arn
}

output "automation_access_key_ids" {
  description = "List of access key IDs for the automation user"
  value       = module.us_ent_east_automation_user.access_key_ids
}

output "ec2_tf_automation_instance_profile_name" {
  description = "Name of the EC2 Terraform automation instance profile"
  value       = module.ec2_tf_automation_role.instance_profile_name
}

output "ec2_tf_automation_instance_profile_arn" {
  description = "ARN of the EC2 Terraform automation instance profile"
  value       = module.ec2_tf_automation_role.instance_profile_arn
}

output "ec2_tf_automation_role_arn" {
  description = "ARN of the EC2 Terraform automation IAM role"
  value       = module.ec2_tf_automation_role.role_arn
}

output "ec2_tf_automation_role_name" {
  description = "Name of the EC2 Terraform automation IAM role"
  value       = module.ec2_tf_automation_role.role_name
}

# NOTE: jenkins_server_role outputs would go here when uncommented
# Currently commented because jenkins_server_role module is not active
/*
output "jenkins_instance_profile_name" {
  description = "Name of the Jenkins instance profile"
  value       = module.jenkins_server_role.jenkins_instance_profile_name
}
*/
