terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.36"
    }
    conjur = {
      source  = "cyberark/conjur"
      version = "~> 0.8.1"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
