resource "random_password" "local_admin_password" {
  length  = 24
  special = true
  override_special = "!@#%^*()-_=+[]{}"
}

locals {
    rename_join_script = templatefile("${path.module}/scripts/rename_and_domain_join.ps1.tpl", {
    hostname                = var.hostname
    region                  = var.region
    domain_join_secret_arn = var.domain_join_secret_arn
    domain_name             = var.domain_name
  })

    register_script = templatefile("${path.module}/scripts/register_connector.ps1.tpl", {
    region               = var.region
    identity_secret_arn = var.identity_secret_arn
    connector_pool_name = var.connector_pool_name
    identity_tenant_id      = var.identity_tenant_id
    platform_tenant_name    = var.platform_tenant_name
  })

  init_script = file("${path.module}/scripts/init.ps1")
  
    user_data = templatefile("${path.module}/scripts/user_data.tpl", {
    hostname              = var.hostname
    region                = var.region
    domain_name           = var.domain_name
    domain_join_secret_arn = var.domain_join_secret_arn
    identity_secret_arn   = var.identity_secret_arn
    connector_pool_name   = var.connector_pool_name
    identity_tenant_id    = var.identity_tenant_id
    platform_tenant_name  = var.platform_tenant_name
    local_admin_password  = random_password.local_admin_password.result

    init_script           = local.init_script
    register_script       = local.register_script
    rename_join_script    = local.rename_join_script
  })
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
    http_tokens = "required"
    http_endpoint = "enabled"
  }
  tags = {
    Name          = var.hostname
    Owner         = var.asset_owner_name
    CA_iScheduler = var.iScheduler
  }
}




