resource "aws_instance" "us-ent-east-dc1" {
  ami                         = var.windows_ami_id
  instance_type               = var.windows_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = var.security_group_ids
  private_ip                  = var.private_ip

  tags = {
    Name  = "${var.team_name}-dc1"
    I_Owner = var.asset_owner_name
    I_Purpose = "Murphy's Lab Domain Controller"
    CA_iScheduler = var.iScheduler
  }

  lifecycle {
    ignore_changes = [ tags ]
  }
}