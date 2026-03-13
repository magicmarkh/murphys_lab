# =====================================================================
# Demo Linux Target with CyberArk SSH Public Key Management
#
# This is a self-contained demonstration that shows:
# 1. Deploying a Linux EC2 instance
# 2. Adding a CyberArk-managed SSH public key using the idsec provider
#
# All components are in this single file for easy demonstration.
# =====================================================================

# =====================================================================
# Provider: Conjur - For retrieving secrets
# =====================================================================
provider "conjur" {
  appliance_url = var.conjur_appliance_url
  account       = var.conjur_account
  api_key       = var.conjur_api_key
  authn_type    = "api"
  login         = var.conjur_login
}

# =====================================================================
# Data Sources: Conjur Secrets
# =====================================================================
data "conjur_secret" "aws_access_key" {
  name = var.conjur_aws_access_key_path
}

data "conjur_secret" "aws_secret_key" {
  name = var.conjur_aws_secret_key_path
}

data "conjur_secret" "identity_client_id" {
  name = var.conjur_identity_client_id_path
}

data "conjur_secret" "identity_client_secret" {
  name = var.conjur_identity_client_secret_path
}

# =====================================================================
# Provider: AWS
# =====================================================================
provider "aws" {
  region     = var.region
  access_key = data.conjur_secret.aws_access_key.value
  secret_key = data.conjur_secret.aws_secret_key.value
}

# =====================================================================
# Provider: CyberArk Identity Security (IDSec)
# =====================================================================
provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = data.conjur_secret.identity_client_id.value
  service_token = data.conjur_secret.identity_client_secret.value
}

# =====================================================================
# Data Sources: Remote State (Foundation Layer)
# =====================================================================
data "terraform_remote_state" "foundation" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = var.foundation_state_key
    region = var.state_region
  }
}

# =====================================================================
# Data Sources: Get Latest Amazon Linux AMI
# =====================================================================
data "aws_ami" "amazon_linux_latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# =====================================================================
# EC2 Instance: Amazon Linux 2023
# =====================================================================
resource "aws_instance" "demo_linux_target" {
  ami                         = data.aws_ami.amazon_linux_latest.id
  instance_type               = var.instance_type
  subnet_id                   = data.terraform_remote_state.foundation.outputs.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids = [
    data.terraform_remote_state.foundation.outputs.ssh_internal_flat_sg_id,
    data.terraform_remote_state.foundation.outputs.sia_linux_target_sg_id
  ]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name                 = "${var.team_name}-${var.hostname}"
    I_Owner              = var.asset_owner_name
    I_Purpose            = "Demo Linux Target - CyberArk SSH Key Management"
    CA_iScheduler        = var.iScheduler
    CA_iSchedulerControl = "yes"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# =====================================================================
# CyberArk SSH Public Key: Add public key to Linux system
# =====================================================================
resource "idsec_sia_ssh_public_key" "demo_linux_target_key" {
  target_machine = aws_instance.demo_linux_target.private_ip
  username = "ec2-user"
  private_key_path = "../keys/demo_linux_target_key.pem"

  depends_on = [aws_instance.demo_linux_target]

}
