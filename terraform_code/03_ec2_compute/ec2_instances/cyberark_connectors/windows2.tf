resource "random_password" "local_admin_password" {
  length           = 24
  special          = true
  override_special = "!@#%^*()-_=+[]{}"
}

locals {
  user_data = templatefile("${path.module}/scripts/user_data.tpl", {
    local_admin_password = random_password.local_admin_password.result
  })
}

resource "aws_instance" "connector_3" {
  ami                         = var.windows_ami_id
  instance_type               = var.windows_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = var.windows_security_group_ids
  private_ip                  = "192.168.20.27"
  disable_api_termination     = true
  user_data                   = local.user_data

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  
  tags = {
    Name                 = "${var.team_name}-connector-3"
    I_Owner              = var.asset_owner_name
    I_Purpose            = "demo-connector"
    CA_iScheduler        = var.iScheduler
    CA_iSchedulerControl = "yes"
  }

  lifecycle {
    ignore_changes  = [tags]
    prevent_destroy = true
  }
}


resource "null_resource" "join_domain" {
  depends_on = [aws_instance.connector_3]

  provisioner "local-exec" {
    command = <<EOT
cd ../../ansible && ansible-playbook \
  -i '${aws_instance.connector_3.private_ip},' \
  -e 'ansible_user=Administrator' \
  -e 'ansible_password=${random_password.local_admin_password.result}' \
  -e 'ansible_connection=winrm' \
  -e 'ansible_port=5985' \
  -e 'ansible_winrm_scheme=http' \
  -e 'ansible_winrm_server_cert_validation=ignore' \
  -e 'hostname=${var.hostname}' \
  -e 'domain_join_username=${var.domain_join_username}@${var.domain_name}' \
  -e 'domain_join_password=${var.domain_join_password}' \
  -e 'domain_name=${var.domain_name}' \
  playbooks/onboard_windows_connector.yml
EOT
  }
}

resource "idsec_sia_access_connector" "windows_connector" {
  connector_type    = "AWS"
  connector_os      = "linux"
  connector_pool_id = "2fc8846d-2e29-4aa8-b8a2-d3b4738c8e5e"
  target_machine    = "192.168.20.27"
  username          = "Administrator"
  password  = var.domain_join_password
  depends_on = [aws_instance.connector_3]
  winrm_protocol = "http"
}
