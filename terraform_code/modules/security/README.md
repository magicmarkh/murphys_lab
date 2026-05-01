# Security Modules

Security related modules for IAM roles, policies and key pairs. Using these modules ensures that access to AWS resources in the lab follows best practices.

## Usage
Invoke the required IAM role or key module from your configuration. Example:

```hcl
module "ec2_asm_role" {
  source = "./modules/security/iam_roles/ec2_asm_role"
}
```
Before applying, verify that your IAM identity has the ability to create roles and policies.
