output "instance_id" {
  description = "The ID of the SCA MCP Server instance"
  value       = aws_instance.sca_mcp_server.id
}

output "private_ip" {
  description = "The private IP address of the SCA MCP Server instance"
  value       = aws_instance.sca_mcp_server.private_ip
}