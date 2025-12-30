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
# REMOTE STATE - CyberArk Layer
# =====================================================================
data "terraform_remote_state" "cyberark" {
  backend = "s3"

  config = {
    bucket = "us-ent-east"
    key    = "terraform/cyberark.tfstate"
    region = "us-east-2"
  }
}

# =====================================================================
# FOUNDATION MODULES - Managed in foundation/ directory
# These modules are now managed separately and accessed via remote state
# =====================================================================

/*
module "vpc" {
  source              = "./modules/networking/vpc"
  region              = var.region
  asset_owner_name    = var.asset_owner_name
  team_name           = var.team_name
  private_subnet_az   = var.private_subnet_az
  public_subnet_az    = var.public_subnet_az
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  domain_name         = var.domain_name
  dns_server_ip       = var.dc1_private_ip
}

module "s3_bucket" {
  source             = "./modules/s3_bucket"
  region             = var.region
  asset_owner_name   = var.asset_owner_name
  bucket_name        = var.team_name
  s3_vpc_endpoint_id = module.vpc.s3_vpc_endpoint_id
}

module "security_groups" {
  source              = "./modules/networking/security_groups"
  asset_owner_name    = var.asset_owner_name
  vpc_id              = module.vpc.vpc_id
  trusted_ips         = var.trusted_ips
  team_name           = var.team_name
  internal_subnets    = ["${var.public_subnet_cidr}", "${var.private_subnet_cidr}"]
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr  = var.public_subnet_cidr
}
*/

# =====================================================================
# APPLICATION LAYER MODULES
# =====================================================================

module "key_pair" {
  source           = "./modules/security/key_pair"
  server_key_name  = "${var.team_name}-key"
  team_name        = var.team_name
  asset_owner_name = var.asset_owner_name
}

/*
module "ec2_public_server" {
  source                     = "./modules/infrastructure/ec2_instances/ec2_public_server"
  vpc_id                     = data.terraform_remote_state.foundation.outputs.vpc_id
  public_subnet_id           = data.terraform_remote_state.foundation.outputs.public_subnet_id
  team_name                  = var.team_name
  asset_owner_name           = var.asset_owner_name
  linux_ami_id               = var.amzn_linux_ami_id
  windows_ami_id             = var.amzn_windows_server_ami_id
  key_name                   = module.key_pair.key_name
  trusted_ips                = var.trusted_ips
  iScheduler                 = var.iScheduler
  linux_security_group_ids   = data.terraform_remote_state.foundation.outputs.trusted_ssh_external_security_group_id
  windows_security_group_ids = data.terraform_remote_state.foundation.outputs.trusted_rdp_external_security_group_id
}

module "automation_station" {
  source                 = "./modules/infrastructure/ec2_instances/automation_station"
  vpc_id                 = data.terraform_remote_state.foundation.outputs.vpc_id
  private_subnet_id      = data.terraform_remote_state.foundation.outputs.private_subnet_id
  team_name              = var.team_name
  asset_owner_name       = var.asset_owner_name
  ami_id                 = var.amzn_linux_ami_id
  key_name               = module.key_pair.key_name
  iScheduler             = var.iScheduler
  vpc_security_group_ids = [data.terraform_remote_state.foundation.outputs.ssh_internal_flat_sg_id, data.terraform_remote_state.foundation.outputs.jenkins_8080_flat_sg_id]
  private_ip_address     = var.automation_station_private_ip
}
*/
module "dc" {
  source             = "./modules/infrastructure/ec2_instances/dc"
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
  source                         = "./modules/infrastructure/ec2_instances/cyberark_connectors"
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

# =====================================================================
# SECURITY MODULES - Managed in security/ directory
# These modules are now managed separately and accessed via remote state
# =====================================================================

/*
module "aws_sm_secrets" {
  source                  = "./modules/security/aws_sm_secrets"
  domain_join_password    = var.domain_join_password
  domain_join_secret_name = var.domain_join_secret_name
  domain_join_username    = var.domain_join_username
}

module "secrets_hub_onboarding_role" {
  source                    = "./modules/security/iam_roles/secrets_hub_onboarding_role"
  SecretsManagerRegion      = var.region
  CyberArkSecretsHubRoleARN = var.CyberArkSecretsHubRoleARN
}

module "ec2_asm_role" {
  source              = "./modules/security/iam_roles/ec2_asm_role"
  cyberark_secret_arn = [var.cyberark_secret_arn]
}

module "cybr_mcp_server_role" {
  source              = "./modules/security/iam_roles/cybr_mcp_server_role"
  cyberark_secret_arn = [var.cyberark_secret_arn]
}
*/

# =====================================================================
# CYBERARK MODULES - Managed in cyberark/ directory
# These modules are now managed separately and accessed via remote state
# =====================================================================

/*
module "connector_manager" {
  source              = "./modules/cyberark/connector_manager"
  network_name        = var.connector_network_name
  pool_name           = var.connector_pool_name1
  pool_description    = var.connector_pool_description
  tags                = var.connector_manager_tags
  pool_identifiers    = var.connector_pool_identifiers
}
*/

module "aws_sia_conector" {
  source                         = "./modules/infrastructure/ec2_instances/aws_sia_connector"
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
  source                        = "./modules/infrastructure/ec2_instances/targets"
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

/*
module "cybr_mcp_server" {
  source                        = "./modules/infrastructure/ec2_instances/cybr_mcp_server"
  vpc_id                        = data.terraform_remote_state.foundation.outputs.vpc_id
  team_name                     = var.team_name
  asset_owner_name              = var.asset_owner_name
  key_name                      = module.key_pair.key_name
  iScheduler                    = var.iScheduler
  ami_id                        = var.amzn_linux_ami_id
  vpc_security_group_ids        = data.terraform_remote_state.foundation.outputs.ssh_internal_flat_sg_id
  private_subnet_id             = data.terraform_remote_state.foundation.outputs.private_subnet_id
  private_ip_address            = var.mcp_server_private_ip
  region                        = var.region
  cyberark_secret_arn           = var.cyberark_secret_arn
  identity_tenant_id            = var.identity_tenant_id
  platform_tenant_name          = var.platform_tenant_name
  workspace_id                  = data.aws_caller_identity.current.account_id
  workspace_type                = var.workspace_type
  mcp_server_hostname           = var.mcp_server_hostname
  ec2_asm_instance_profile_name = data.terraform_remote_state.security.outputs.cybr_mcp_server_instance_profile_name
  username_domain               = var.username_domain
}*/

module "db_subnet_group" {
  source             = "./modules/networking/db_subnet_group"
  team_name          = var.team_name
  private_subnet_ids = [data.terraform_remote_state.foundation.outputs.private_subnet_id, data.terraform_remote_state.foundation.outputs.public_subnet_id]
}

module "mysql" {
  source                 = "./modules/infrastructure/rds/mysql"
  iScheduler             = var.iScheduler
  db_subnet_group_name   = module.db_subnet_group.db_subnet_group_name
  asset_owner_name       = var.asset_owner_name
  vpc_security_group_ids = [data.terraform_remote_state.foundation.outputs.mysql_target_sg_id]
}

module "postgresql" {
  source                 = "./modules/infrastructure/rds/postgresql"
  iScheduler             = var.iScheduler
  db_subnet_group_name   = module.db_subnet_group.db_subnet_group_name
  asset_owner_name       = var.asset_owner_name
  vpc_security_group_ids = [data.terraform_remote_state.foundation.outputs.postgresql_target_sg_id]
  team_name              = var.team_name
}

module "mssql" {
  source                 = "./modules/infrastructure/rds/mssql"
  iScheduler             = var.iScheduler
  db_subnet_group_name   = module.db_subnet_group.db_subnet_group_name
  asset_owner_name       = var.asset_owner_name
  vpc_security_group_ids = [data.terraform_remote_state.foundation.outputs.mssql_target_sg_id]
  domain_auth_secret_arn = var.mssql_domain_join_arn
  domain_ou              = var.mssql_domain_ou
}

/*
module "connector2" {
  source                     = "./modules/infrastructure/ec2_instances/connector2"
  iScheduler                 = var.iScheduler
  windows_security_group_ids = [data.terraform_remote_state.foundation.outputs.rdp_internal_flat_sg_id, data.terraform_remote_state.foundation.outputs.winrm_internal_flat_sg_id]
  domain_join_secret_arn     = var.domain_join_secret_arn
  iam_instance_profile       = data.terraform_remote_state.security.outputs.ec2_asm_instance_profile_name
  private_subnet_id          = data.terraform_remote_state.foundation.outputs.private_subnet_id
  identity_secret_arn        = var.cyberark_secret_arn
  hostname                   = var.connector_2_hostname
  identity_tenant_id         = var.identity_tenant_id
  platform_tenant_name       = var.platform_tenant_name
  region                     = var.region
  windows_ami_id             = var.amzn_windows_server_ami_id
  team_name                  = var.team_name
  asset_owner_name           = var.asset_owner_name
  key_name                   = module.key_pair.key_name
  vpc_id                     = data.terraform_remote_state.foundation.outputs.vpc_id
  connector_pool_name        = var.connector_pool_name
  private_ip                 = var.connector_2_private_ip
  domain_name                = var.domain_name
}
*/