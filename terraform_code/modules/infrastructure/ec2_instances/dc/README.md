# Domain Controller Module

This module provisions a Windows Server instance configured to act as the lab's Active Directory domain controller. It can also create the necessary IAM role to allow the instance to join other servers to the domain.

## Usage
```hcl
module "dc" {
  source    = "./modules/infrastructure/ec2_instances/dc"
  subnet_id = module.vpc.private_subnet_id
}
```
Ensure your IAM user can create service-linked roles and `ec2:*` resources when applying this module.
