# S3 Bucket Module

Creates an S3 bucket for storing lab artifacts such as installation media or Terraform state. The bucket is configured with server-side encryption and private access by default.

## Usage
```hcl
module "s3_bucket" {
  source = "./modules/s3_bucket"
  bucket_name = "my-lab-bucket"
}
```
The IAM principal running Terraform must have permission to manage S3 buckets (`s3:*`). Consider enabling versioning if storing state files.
