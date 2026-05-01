# MySQL RDS Module

This module spins up an Amazon RDS MySQL instance. It exposes variables for storage size, instance class, username and password.

## Usage
```hcl
module "mysql" {
  source            = "./modules/infrastructure/rds/mysql"
  db_subnet_group_name = module.db_subnet_group.name
  vpc_security_group_ids = [module.db_sg.id]
}
```
Refer to `variables.tf` for a full list of configuration options. The IAM user executing Terraform must have permissions to create RDS instances.
