output "trusted_ssh_external_security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.ssh_from_trusted_ips.id
}

output "trusted_ssh_external_security_group_name" {
  description = "The name of the security group"
  value       = aws_security_group.ssh_from_trusted_ips.name
}

output "trusted_rdp_external_security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.rdp_from_trusted_ips.id
}

output "trusted_rdp_external_security_group_name" {
  description = "The name of the security group"
  value       = aws_security_group.rdp_from_trusted_ips.name
}


output "ssh_internal_flat_sg_id" {
  description = "The ID of the security group"
  value = aws_security_group.ssh_internal_flat.id
}

output "ssh_internal_flat_sg_name" {
  description = "The name of the security group"
  value = aws_security_group.ssh_internal_flat.name
}

output "rdp_internal_flat_sg_id" {
  description = "The ID of the security group"
  value = aws_security_group.rdp_internal_flat.id
}

output "rdp_internal_flat_sg_name" {
  description = "The name of the security group"
  value = aws_security_group.rdp_internal_flat.name
}

output "jenkins_8080_flat_sg_id" {
  description = "The ID of the security group"
  value = aws_security_group.jenkins_8080.id
}

output "jenkins_8080_flat_sg_name" {
  description = "The name of the security group"
  value = aws_security_group.jenkins_8080.name
}

output "domain_controller_sg_id" {
  description = "The ID of the security group"
  value = aws_security_group.domain_controller_sg.id
}

output "domain_controller_sg_name" {
  description = "The name of the security group"
  value = aws_security_group.domain_controller_sg.name
}

output "sia_windows_target_sg_id" {
  description = "The ID of the security group"
  value = aws_security_group.sia_windows_target_sg.id
}

output "sia_windows_target_sg_name" {
  description = "The name of the security group"
  value = aws_security_group.sia_windows_target_sg.name
}

output "mysql_target_sg_id" {
  description = "The id of the security group"
  value = aws_security_group.mysql_target_sg.id
}

output "postgresql_target_sg_id" {
  description = "The id of the security group"
  value = aws_security_group.postgresql_target_sg.id
}

output "winrm_internal_flat_sg_id" {
  description = "The id of the security group"
  value = aws_security_group.winrm_internal_flat.id
}

output "mssql_target_sg_id" {
  description = "The id of the security group"
  value = aws_security_group.mssql_target_sg.id
}

output "https_internal_flat_sg_id" {
  description = "The ID of the security group"
  value = aws_security_group.https_internal_flat.id
}

output "https_internal_flat_sg_name" {
  description = "The name of the security group"
  value = aws_security_group.https_internal_flat.name
}