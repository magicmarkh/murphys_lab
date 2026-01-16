# Data source to get AWS account ID
data "aws_caller_identity" "current" {}

# Data source to reference infrastructure outputs
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = var.foundation_state_key
    region = var.state_region
  }
}

# Local values combining infrastructure outputs
locals {
  pool_identifiers = {
    "CyberArkCloudDomain" = {
      value = "*.cyberark.cloud"
      type  = "GENERAL_FQDN"
    }
    "AWSRdsDomain" = {
      value = "*.${var.rds_domain_name}"
      type  = "GENERAL_FQDN"
    }
    "aws_vpc" = {
      value = data.terraform_remote_state.foundation.outputs.vpc_id
      type  = "AWS_VPC"
    }
    "aws_subnet" = {
      value = "${data.terraform_remote_state.foundation.outputs.vpc_id}/${data.terraform_remote_state.foundation.outputs.private_subnet_id}"
      type  = "AWS_SUBNET"
    }
    "aws_account" = {
      value = data.aws_caller_identity.current.account_id
      type  = "AWS_ACCOUNT_ID"
    }
    "active_directory_domain" = {
      value = var.ad_domain_name
      type  = "GENERAL_FQDN"
    }
    "active_directory_domain_subtargets" = {
      value = "*.${var.ad_domain_name}"
      type  = "GENERAL_FQDN"
    }
  }
}

resource "idsec_cmgr_network" "networks" {
  for_each = toset(var.networks)

  name = each.value

    lifecycle {
    prevent_destroy = true
  }
}

resource "idsec_cmgr_pool" "main" {
  name                 = var.pool_name
  description          = var.pool_description
  assigned_network_ids = [for network in idsec_cmgr_network.networks : network.network_id]

    lifecycle {
    prevent_destroy = true
  }
}

resource "idsec_cmgr_pool_identifier" "identifiers" {
  for_each = local.pool_identifiers

  value   = each.value.value
  pool_id = idsec_cmgr_pool.main.pool_id
  type    = each.value.type


    lifecycle {
    prevent_destroy = true
  }
}
