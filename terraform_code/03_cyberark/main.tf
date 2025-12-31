data "aws_caller_identity" "current" {}

# =====================================================================
# REMOTE STATE - Foundation Layer
# =====================================================================
data "terraform_remote_state" "foundation" {
  backend = "s3"

  config = {
    bucket = "us-ent-east"
    key    = "terraform/01_foundation.tfstate"
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
    key    = "terraform/02_security.tfstate"
    region = "us-east-2"
  }
}

# =====================================================================
# CYBERARK IDENTITY - Connector Manager
# =====================================================================
module "connector_manager" {
  source              = "./connector_manager"
  network_name        = var.connector_network_name
  pool_name           = var.connector_pool_name1
  pool_description    = var.connector_pool_description
  tags                = var.connector_manager_tags
  pool_identifiers    = var.connector_pool_identifiers
}
