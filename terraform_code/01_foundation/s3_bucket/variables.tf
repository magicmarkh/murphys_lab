variable "region" {}

variable "asset_owner_name" {}

variable "vpc_state_file_path" {
  description = "Path to networking.tfstate to read VPC outputs"
  type        = string
  default     = "./terraform.tfstate"
}

variable "bucket_name" {}

variable "allowed_ips" {
  description = "Additional IPs/CIDRs allowed to access the bucket"
  type        = list(string)
  default     = ["134.238.168.126/32"]
}

variable "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC endpoint to allow in the bucket policy"
  type        = string
}


