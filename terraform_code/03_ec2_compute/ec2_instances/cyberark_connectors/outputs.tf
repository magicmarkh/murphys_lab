# =====================================================================
# Linux Connector Outputs
# =====================================================================
output "linux_connector_instance_ids" {
  description = "List of instance IDs for Linux SIA connectors"
  value       = aws_instance.sia_linux_aws_connector[*].id
}

output "linux_connector_private_ips" {
  description = "List of private IP addresses for Linux SIA connectors"
  value       = aws_instance.sia_linux_aws_connector[*].private_ip
}

output "linux_connector_hostnames" {
  description = "List of hostnames for Linux SIA connectors"
  value       = [for i in range(var.linux_connector_count) : "${var.linux_connector_hostname_prefix}-${i + 1}"]
}

output "linux_connector_count" {
  description = "Number of Linux SIA connectors deployed"
  value       = var.linux_connector_count
}
