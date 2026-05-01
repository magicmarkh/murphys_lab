# Security Groups Module

Contains reusable security group definitions for controlling inbound and outbound traffic. Apply this module to enforce network policies around your EC2 instances and RDS databases.

## Usage
```hcl
module "security_groups" {
  source = "./modules/networking/security_groups"
}
```
Modify `variables.tf` to adjust default ports or create additional groups.
