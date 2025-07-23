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

data "aws_secretsmanager_secret_version" "domain_join_credentials" {
  secret_id = var.domain_join_secret_arn
}

data "aws_secretsmanager_secret_version" "identity_credentials" {
  secret_id = var.identity_secret_arn
}

resource "aws_instance" "connector_2" {
  ami                         = var.windows_ami_id
  instance_type               = var.windows_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = var.windows_security_group_ids
  iam_instance_profile        = var.iam_instance_profile
  private_ip                  = var.private_ip
  user_data                   = local.user_data

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  tags = {
    Name          = var.hostname
    Owner         = var.asset_owner_name
    CA_iScheduler = var.iScheduler
  }
}


resource "null_resource" "configure_connector" {
  depends_on = [aws_instance.connector_2]

    provisioner "local-exec" {
    command = <<EOT
cd ../ansible && ansible-playbook \
  -i '${aws_instance.connector_2.private_ip},' \
  -e 'ansible_user=Administrator' \
  -e 'ansible_password=${random_password.local_admin_password.result}' \
  -e 'ansible_connection=winrm' \
  -e 'ansible_port=5985' \
  -e 'ansible_winrm_scheme=http' \
  -e 'ansible_winrm_server_cert_validation=ignore' \
  -e 'hostname=${var.hostname}' \
  -e 'aws_region=${var.region}' \
  -e 'domain_join_username=${jsondecode(data.aws_secretsmanager_secret_version.domain_join_credentials.secret_string)["username"]}@murphyslab.local' \
  -e 'domain_join_password=${jsondecode(data.aws_secretsmanager_secret_version.domain_join_credentials.secret_string)["password"]}' \
  -e 'identity_username=${jsondecode(data.aws_secretsmanager_secret_version.identity_credentials.secret_string)["username"]}@murphys.cloud' \
  -e 'identity_password=${jsondecode(data.aws_secretsmanager_secret_version.identity_credentials.secret_string)["password"]}' \
  -e 'domain_name=${var.domain_name}' \
  -e 'identity_tenant_id=${var.identity_tenant_id}' \
  -e 'platform_tenant_name=${var.platform_tenant_name}' \
  -e 'connector_pool_name=${var.connector_pool_name}' \
  playbooks/onboard_windows_connector.yml
EOT
  }
}
