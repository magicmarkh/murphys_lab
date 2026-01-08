data "aws_caller_identity" "current" {}

# =====================================================================
# REMOTE STATE - Foundation Layer
# =====================================================================
data "terraform_remote_state" "foundation" {
  backend = "s3"

  config = {
    bucket = "us-ent-east"
    key    = "terraform/foundation.tfstate"
    region = "us-east-2"
  }
}

# =====================================================================
# REMOTE STATE - Security Layer
# =====================================================================
data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = "us-ent-east"
    key    = "terraform/security.tfstate"
    region = "us-east-2"
  }
}

# =====================================================================
# KEY PAIR
# =====================================================================
module "key_pair" {
  source           = "./key_pair"
  server_key_name  = "${var.team_name}-key"
  team_name        = var.team_name
  asset_owner_name = var.asset_owner_name
}

# =====================================================================
# EC2 INSTANCES
# =====================================================================
module "dc" {
  source             = "./ec2_instances/dc"
  vpc_id             = data.terraform_remote_state.foundation.outputs.vpc_id
  team_name          = var.team_name
  asset_owner_name   = var.asset_owner_name
  key_name           = module.key_pair.key_name
  iScheduler         = var.iScheduler
  security_group_ids = [data.terraform_remote_state.foundation.outputs.rdp_internal_flat_sg_id, data.terraform_remote_state.foundation.outputs.domain_controller_sg_id]
  private_ip         = var.dc1_private_ip
  private_subnet_id  = data.terraform_remote_state.foundation.outputs.private_subnet_id
}

module "cyberark_connectors" {
  source                         = "./ec2_instances/cyberark_connectors"
  vpc_id                         = data.terraform_remote_state.foundation.outputs.vpc_id
  team_name                      = var.team_name
  asset_owner_name               = var.asset_owner_name
  windows_ami_id                 = var.amzn_windows_server_ami_id
  key_name                       = module.key_pair.key_name
  iScheduler                     = var.iScheduler
  windows_security_group_ids     = [
    data.terraform_remote_state.foundation.outputs.rdp_internal_flat_sg_id,
    data.terraform_remote_state.foundation.outputs.https_internal_flat_sg_id
  ]
  private_subnet_id              = data.terraform_remote_state.foundation.outputs.private_subnet_id
  connector_1_private_ip         = var.connector_1_private_ip
  sia_aws_connector_1_private_ip = var.sia_aws_connector_1_private_ip
}

module "aws_sia_connector" {
  source                         = "./ec2_instances/aws_sia_connector"
  private_subnet_id              = data.terraform_remote_state.foundation.outputs.private_subnet_id
  key_name                       = module.key_pair.key_name
  team_name                      = var.team_name
  linux_security_group_ids       = data.terraform_remote_state.foundation.outputs.ssh_internal_flat_sg_id
  vpc_id                         = data.terraform_remote_state.foundation.outputs.vpc_id
  linux_ami_id                   = var.amzn_linux_ami_id
  iScheduler                     = var.iScheduler
  asset_owner_name               = var.asset_owner_name
  sia_aws_connector_1_private_ip = var.sia_aws_connector_1_private_ip
  region                         = var.region
  connector_pool_name            = var.connector_pool_name
  cyberark_secret_arn            = var.cyberark_secret_arn
  identity_tenant_id             = var.identity_tenant_id
  platform_tenant_name           = var.platform_tenant_name
  ec2_asm_instance_profile_name  = data.terraform_remote_state.security.outputs.ec2_asm_instance_profile_name
}

module "targets" {
  source                        = "./ec2_instances/targets"
  vpc_id                        = data.terraform_remote_state.foundation.outputs.vpc_id
  team_name                     = var.team_name
  asset_owner_name              = var.asset_owner_name
  key_name                      = module.key_pair.key_name
  iScheduler                    = var.iScheduler
  linux_ami_id                  = var.amzn_linux_ami_id
  windows_security_group_ids    = [data.terraform_remote_state.foundation.outputs.rdp_internal_flat_sg_id, data.terraform_remote_state.foundation.outputs.sia_windows_target_sg_id]
  linux_security_group_ids      = data.terraform_remote_state.foundation.outputs.ssh_internal_flat_sg_id
  private_subnet_id             = data.terraform_remote_state.foundation.outputs.private_subnet_id
  windows_target_1_private_ip   = var.windows_target_1_private_ip
  linux_target_1_private_ip     = var.linux_target_1_private_ip
  region                        = var.region
  cyberark_secret_arn           = var.cyberark_secret_arn
  identity_tenant_id            = var.identity_tenant_id
  platform_tenant_name          = var.platform_tenant_name
  workspace_id                  = data.aws_caller_identity.current.account_id
  workspace_type                = var.workspace_type
  linux_target_1_hostname       = var.linux_target_1_hostname
  ec2_asm_instance_profile_name = data.terraform_remote_state.security.outputs.ec2_asm_instance_profile_name
  windows_ami_id                = var.amzn_windows_server_ami_id
}
