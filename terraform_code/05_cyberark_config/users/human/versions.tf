terraform {
  required_version = ">= 1.3.0"
  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 0.1.8"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
