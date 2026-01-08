resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "server" {
  key_name   = var.server_key_name
  public_key = tls_private_key.server.public_key_openssh

  tags = {
    Name  = "${var.team_name}-key"
    Owner = var.asset_owner_name
  }
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.server.private_key_pem
  filename = "${path.module}/${var.server_key_name}.pem"
}
