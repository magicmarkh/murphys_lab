# ===========================
# VPC Outputs
# ===========================
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = module.vpc.private_subnet_id
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC Gateway Endpoint"
  value       = module.vpc.s3_vpc_endpoint_id
}

# ===========================
# S3 Bucket Outputs
# ===========================
output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3_bucket.bucket_arn
}

output "bucket_id" {
  description = "The ID of the S3 bucket"
  value       = module.s3_bucket.bucket_id
}

# ===========================
# Security Group Outputs
# ===========================
output "trusted_ssh_external_security_group_id" {
  description = "ID of trusted SSH external security group"
  value       = module.security_groups.trusted_ssh_external_security_group_id
}

output "trusted_rdp_external_security_group_id" {
  description = "ID of trusted RDP external security group"
  value       = module.security_groups.trusted_rdp_external_security_group_id
}

output "ssh_internal_flat_sg_id" {
  description = "ID of SSH internal flat security group"
  value       = module.security_groups.ssh_internal_flat_sg_id
}

output "rdp_internal_flat_sg_id" {
  description = "ID of RDP internal flat security group"
  value       = module.security_groups.rdp_internal_flat_sg_id
}

output "jenkins_8080_flat_sg_id" {
  description = "ID of Jenkins 8080 security group"
  value       = module.security_groups.jenkins_8080_flat_sg_id
}

output "domain_controller_sg_id" {
  description = "ID of domain controller security group"
  value       = module.security_groups.domain_controller_sg_id
}

output "sia_windows_target_sg_id" {
  description = "ID of SIA Windows target security group"
  value       = module.security_groups.sia_windows_target_sg_id
}

output "mysql_target_sg_id" {
  description = "ID of MySQL target security group"
  value       = module.security_groups.mysql_target_sg_id
}

output "postgresql_target_sg_id" {
  description = "ID of PostgreSQL target security group"
  value       = module.security_groups.postgresql_target_sg_id
}

output "winrm_internal_flat_sg_id" {
  description = "ID of WinRM internal flat security group"
  value       = module.security_groups.winrm_internal_flat_sg_id
}

output "mssql_target_sg_id" {
  description = "ID of MSSQL target security group"
  value       = module.security_groups.mssql_target_sg_id
}

output "https_internal_flat_sg_id" {
  description = "ID of HTTPS internal flat security group"
  value       = module.security_groups.https_internal_flat_sg_id
}
