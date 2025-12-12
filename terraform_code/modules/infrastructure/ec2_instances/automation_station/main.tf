// modules/automation_station/main.tf
# load the bootstrap script
locals {
  bootstrap_script = templatefile("${path.module}/scripts/init.sh", {})
}

#create the instance
resource "aws_instance" "automation_station" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  associate_public_ip_address = false
  private_ip   = var.private_ip_address

  # <<< this kicks off your init.sh on first boot
  user_data = local.bootstrap_script

  tags = {
    Name = "${var.team_name}-automation-station"
    Owner = var.asset_owner_name
    CA_iScheduler = var.iScheduler
    CA_iSchedulerControl = "yes"
  }
}
