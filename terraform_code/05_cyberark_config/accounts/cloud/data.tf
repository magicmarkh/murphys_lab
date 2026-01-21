data "aws_caller_identity" "current" {}

data "terraform_remote_state" "ec2_compute" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = var.ec2_compute_state_key
    region = var.state_region
  }
}
