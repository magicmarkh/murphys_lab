output "key_name" {
  value = aws_key_pair.server.key_name
}

output "private_key_path" {
  value = local_file.private_key_pem.filename
}

output "private_key_pem" {
  description = "Private key in PEM format"
  value       = tls_private_key.server.private_key_pem
  sensitive   = true
}
