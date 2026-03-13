# ===========================
# EC2 Instance Outputs
# ===========================
output "instance_id" {
  description = "ID of the demo Linux target instance"
  value       = aws_instance.demo_linux_target.id
}

output "instance_private_ip" {
  description = "Private IP address of the demo Linux target"
  value       = aws_instance.demo_linux_target.private_ip
}

output "instance_ami" {
  description = "AMI ID used for the instance"
  value       = aws_instance.demo_linux_target.ami
}

# ===========================
# SSH Public Key Outputs
# ===========================
output "ssh_public_key_id" {
  description = "ID of the CyberArk-managed SSH public key"
  value       = idsec_sia_ssh_public_key.demo_linux_target_key.public_key_id
}

output "ssh_key_fingerprint" {
  description = "Fingerprint of the SSH public key"
  value       = idsec_sia_ssh_public_key.demo_linux_target_key.fingerprint
}
