# =====================================================================
# KEY PAIR OUTPUTS
# =====================================================================
output "key_name" {
  description = "Name of the SSH key pair"
  value       = module.key_pair.key_name
}

# Commented out - modules don't export these outputs yet
# output "key_pair_id" {
#   description = "ID of the SSH key pair"
#   value       = module.key_pair.key_pair_id
# }

# # =====================================================================
# # EC2 INSTANCE OUTPUTS
# # =====================================================================
# output "dc_instance_id" {
#   description = "ID of the Domain Controller instance"
#   value       = module.dc.instance_id
# }

# output "cyberark_connector_1_instance_id" {
#   description = "ID of the CyberArk Connector 1 instance"
#   value       = module.cyberark_connectors.connector_1_instance_id
# }

# output "aws_sia_connector_instance_id" {
#   description = "ID of the AWS SIA Connector instance"
#   value       = module.aws_sia_connector.instance_id
# }

# Outputs commented out - targets module doesn't export these outputs yet
# output "linux_target_1_instance_id" {
#   description = "ID of Linux Target 1 instance"
#   value       = module.targets.linux_target_1_instance_id
# }

# output "windows_target_1_instance_id" {
#   description = "ID of Windows Target 1 instance"
#   value       = module.targets.windows_target_1_instance_id
# }
