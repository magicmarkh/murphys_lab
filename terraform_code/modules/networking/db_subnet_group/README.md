# DB Subnet Group Module

Defines a collection of subnets to be used for Amazon RDS instances. The module ensures your database is deployed across multiple Availability Zones for redundancy.

## Usage
```hcl
module "db_subnet_group" {
  source        = "./modules/networking/db_subnet_group"
  subnet_ids    = module.vpc.private_subnet_ids
}
```
Your IAM user must have permission to manage RDS resources to create the subnet group.
