# IAM Role Modules

These modules define IAM roles and associated policies that can be attached to EC2 instances or used by AWS services. Centralizing role definitions simplifies permission management for new practitioners.

## Usage
```hcl
module "jenkins_server_role" {
  source = "./modules/security/iam_roles/jenkins_server_role"
}
```
Review each role's `policies.tf` file for details on the permissions granted.
