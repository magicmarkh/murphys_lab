terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    conjur = {
      source  = "cyberark/conjur"
      version = "~> 0.6"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.4.0"
    }
  }
}
