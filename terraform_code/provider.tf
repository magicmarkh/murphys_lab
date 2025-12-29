provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.36"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.1.3"
    }
  }
}

provider "idsec" {
  auth_method = "identity_service_user"
  service_user     = var.identity_client_id
  service_token = var.identity_client_secret
}
