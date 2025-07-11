terraform {
  backend "s3" {
    bucket  = var.state_bucket
    key     = var.state_bucket_key
    region  = var.region
    encrypt = true
  }
}
