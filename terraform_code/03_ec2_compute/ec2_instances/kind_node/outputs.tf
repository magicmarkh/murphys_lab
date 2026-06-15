output "instance_id" {
  description = "ID of the Kind node EC2 instance"
  value       = aws_instance.kind_node.id
}

output "private_ip" {
  description = "Private IP address of the Kind node"
  value       = aws_instance.kind_node.private_ip
}
