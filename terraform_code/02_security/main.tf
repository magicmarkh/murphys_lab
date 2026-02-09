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

module "ec2_tf_automation_role" {
  source              = "./iam_roles/ec2_tf_automation_role"
  s3_bucket_arn       = data.terraform_remote_state.foundation.outputs.bucket_arn
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

# =====================================================================
# IAM USERS
# =====================================================================
module "us_ent_east_automation_user" {
  source = "./iam_users"

  iam_username  = var.automation_iam_username
  iam_user_path = var.automation_iam_user_path

  tags = {
    Owner       = var.asset_owner_name
    Team        = var.team_name
    Environment = "lab"
  }
}
