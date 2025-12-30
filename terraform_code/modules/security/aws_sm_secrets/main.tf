resource "aws_secretsmanager_secret" "domain_joiner" {
  name = var.domain_join_secret_name
  tags = {
    "Sourced by CyberArk" = ""
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_secretsmanager_secret_version" "domain_joiner_value" {
  count = var.create_secret_version ? 1 : 0
  secret_id     = aws_secretsmanager_secret.domain_joiner.id
  secret_string = jsonencode({
    username = var.domain_join_username,
    password = var.domain_join_password
  })
    
}
