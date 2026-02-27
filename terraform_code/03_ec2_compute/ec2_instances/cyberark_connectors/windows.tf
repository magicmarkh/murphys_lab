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

resource "aws_instance" "connector_1" {
  ami                         = var.windows_ami_id
  instance_type               = var.windows_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = var.windows_security_group_ids
  private_ip                  = var.connector_1_private_ip
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
    Name                 = "${var.team_name}-connector-1"
    I_Owner              = var.asset_owner_name
    I_Purpose            = "Murphy's Lab primary CyberArk Connector"
    CA_iScheduler        = var.iScheduler
    CA_iSchedulerControl = "yes"
  }

  lifecycle {
    ignore_changes  = [tags, ami, user_data]
    prevent_destroy = true
  }
}

resource "null_resource" "join_domain" {
  depends_on = [aws_instance.connector_1]

  provisioner "local-exec" {
    command = <<EOT
cd ../../ansible && ansible-playbook \
  -i '${aws_instance.connector_1.private_ip},' \
  -e 'ansible_user=Administrator' \
  -e 'ansible_password=${random_password.local_admin_password.result}' \
  -e 'ansible_connection=winrm' \
  -e 'ansible_port=5985' \
  -e 'ansible_winrm_scheme=http' \
  -e 'ansible_winrm_server_cert_validation=ignore' \
  -e 'hostname=${var.windows_connector_hostname}' \
  -e 'domain_join_username=${var.domain_join_username}@${var.domain_name}' \
  -e 'domain_join_password=${var.domain_join_password}' \
  -e 'domain_name=${var.domain_name}' \
  playbooks/onboard_windows_connector.yml
EOT
  }
}

# Wait for Windows server to fully stabilize after domain join and reboot
resource "time_sleep" "wait_after_domain_join" {
  depends_on = [null_resource.join_domain]

  create_duration = "180s"  # Wait 3 minutes for server to be fully ready
}

resource "idsec_sia_access_connector" "windows_connector" {
  connector_type    = "AWS"
  connector_os      = "windows"
  connector_pool_id = var.connector_pool_id
  target_machine    = var.connector_1_private_ip
  username          = "${var.domain_join_username}@${var.domain_name}"
  password          = var.domain_join_password
  depends_on        = [time_sleep.wait_after_domain_join]
  winrm_protocol    = "http"

  lifecycle {
    ignore_changes = [
      connector_id,
      password,
      private_key_contents,
      private_key_path
    ]
  }
}
