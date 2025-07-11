terraform {
  backend "s3" {
    bucket  = "us-ent-east"
    key     = "terraform/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}
