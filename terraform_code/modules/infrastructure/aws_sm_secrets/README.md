# AWS Secrets Manager Module

This module creates secrets in AWS Secrets Manager for storing credentials such as the domain join account. Use it to keep passwords out of your configuration files.

## Usage
```hcl
module "aws_sm_secrets" {
  source                 = "./modules/infrastructure/aws_sm_secrets"
  domain_join_username   = "CORP\\joinuser"
  domain_join_password   = "StrongPassword!"        # consider using variables marked sensitive
  domain_join_secret_name = "corp/joinuser"
}
```
Ensure the IAM user running Terraform has permissions to create and update secrets (`secretsmanager:*`).
