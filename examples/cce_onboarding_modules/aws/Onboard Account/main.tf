terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.3.3"
    }
  }
}


provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = var.idsec_service_user
  service_token = var.idsec_service_token
}

provider "aws" {
  region = var.aws_region
}

module "cce_add_account" {
 source  = "cyberark/cce-organization-add-account/aws"
  version = "~> 0.2.0"

  org_onboarding_id = var.org_onboarding_id
  services          = var.services
}