output "instance_id" {
  description = "The ID of the CyberArk MCP Server instance"
  value       = aws_instance.cybr_mcp_server.id
}

output "private_ip" {
  description = "The private IP address of the CyberArk MCP Server instance"
  value       = aws_instance.cybr_mcp_server.private_ip
}