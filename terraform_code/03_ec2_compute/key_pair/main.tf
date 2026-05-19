resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 4096

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_key_pair" "server" {
  key_name   = var.server_key_name
  public_key = tls_private_key.server.public_key_openssh

  tags = {
    Name  = "${var.team_name}-key"
    Owner = var.asset_owner_name
  }

  lifecycle {
    ignore_changes = all
  }
}

