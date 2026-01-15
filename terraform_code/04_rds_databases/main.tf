data "aws_caller_identity" "current" {}

# =====================================================================
# REMOTE STATE - Foundation Layer
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
# DB SUBNET GROUP
# =====================================================================
module "db_subnet_group" {
  source             = "./db_subnet_group"
  team_name          = var.team_name
  private_subnet_ids = [data.terraform_remote_state.foundation.outputs.private_subnet_id, data.terraform_remote_state.foundation.outputs.public_subnet_id]
}

# =====================================================================
# RDS DATABASES
# =====================================================================
module "mysql" {
  source                 = "./rds/mysql"
  iScheduler             = var.iScheduler
  db_subnet_group_name   = module.db_subnet_group.db_subnet_group_name
  asset_owner_name       = var.asset_owner_name
  vpc_security_group_ids = [data.terraform_remote_state.foundation.outputs.mysql_target_sg_id]
}

module "postgresql" {
  source                 = "./rds/postgresql"
  iScheduler             = var.iScheduler
  db_subnet_group_name   = module.db_subnet_group.db_subnet_group_name
  asset_owner_name       = var.asset_owner_name
  vpc_security_group_ids = [data.terraform_remote_state.foundation.outputs.postgresql_target_sg_id]
  team_name              = var.team_name
}

module "mssql" {
  source                 = "./rds/mssql"
  iScheduler             = var.iScheduler
  db_subnet_group_name   = module.db_subnet_group.db_subnet_group_name
  asset_owner_name       = var.asset_owner_name
  vpc_security_group_ids = [data.terraform_remote_state.foundation.outputs.mssql_target_sg_id]
  domain_auth_secret_arn = var.mssql_domain_join_arn
  domain_ou              = var.mssql_domain_ou
}
