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
# SECRETS MANAGER
# =====================================================================
module "aws_sm_secrets" {
  source                  = "./aws_sm_secrets"
  domain_join_password    = var.domain_join_password
  domain_join_secret_name = var.domain_join_secret_name
  domain_join_username    = var.domain_join_username
}

# =====================================================================
# IAM ROLES
# =====================================================================
module "secrets_hub_onboarding_role" {
  source                    = "./iam_roles/secrets_hub_onboarding_role"
  SecretsManagerRegion      = var.region
  CyberArkSecretsHubRoleARN = var.CyberArkSecretsHubRoleARN
}

module "ec2_asm_role" {
  source              = "./iam_roles/ec2_asm_role"
  cyberark_secret_arn = [var.cyberark_secret_arn]
}

module "cybr_mcp_server_role" {
  source              = "./iam_roles/cybr_mcp_server_role"
  cyberark_secret_arn = [var.cyberark_secret_arn]
}

# NOTE: jenkins_server_role is commented out - keeping commented per current state
# Uncomment when needed, but note: this module has a BUG - it's missing an
# aws_iam_instance_profile resource and the output returns policy name instead
/*
module "jenkins_server_role" {
  source           = "../modules/security/iam_roles/jenkins_server_role"
  team_name        = var.team_name
  s3_bucket_arn    = data.terraform_remote_state.foundation.outputs.bucket_arn
  vpc_arn          = data.terraform_remote_state.foundation.outputs.vpc_arn
  asset_owner_name = var.asset_owner_name
}
*/
