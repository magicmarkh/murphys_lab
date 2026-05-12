# ===========================
# EC2 Instance Outputs
# ===========================
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.demo_target.id
}

output "instance_private_ip" {
  description = "Private IP address (DHCP-assigned)"
  value       = aws_instance.demo_target.private_ip
}

output "instance_fqdn" {
  description = "Fully qualified domain name"
  value       = "${var.hostname}.${var.domain_name}"
}

# ===========================
# CyberArk Outputs
# ===========================
output "safe_name" {
  description = "CyberArk safe name"
  value       = idsec_pcloud_safe.demo_target_safe.safe_name
}

output "safe_id" {
  description = "CyberArk safe ID"
  value       = idsec_pcloud_safe.demo_target_safe.safe_id
}

output "account_name" {
  description = "CyberArk account name"
  value       = idsec_pcloud_account.demo_target_admin.name
}

output "account_address" {
  description = "CyberArk account address"
  value       = idsec_pcloud_account.demo_target_admin.address
}

# ===========================
# General Information
# ===========================
output "demo_info" {
  description = "Quick reference information for the demo"
  value = {
    hostname        = var.hostname
    fqdn            = "${var.hostname}.${var.domain_name}"
    private_ip      = aws_instance.demo_target.private_ip
    safe_name       = idsec_pcloud_safe.demo_target_safe.safe_name
    account_name    = idsec_pcloud_account.demo_target_admin.name
    platform        = var.platform_id
    instance_type   = var.instance_type
    region          = var.region
  }
}
