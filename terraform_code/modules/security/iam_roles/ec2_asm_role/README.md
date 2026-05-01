# EC2 Secrets Manager Role

Provides an IAM role that allows EC2 instances to read secrets from AWS Secrets Manager. Attach this role to instances that need access to stored credentials.

## Usage
```hcl
module "ec2_asm_role" {
  source = "./modules/security/iam_roles/ec2_asm_role"
}
```
After creation, reference the role's ARN when launching your EC2 instance.
