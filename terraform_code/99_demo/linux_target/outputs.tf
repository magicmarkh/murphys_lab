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


