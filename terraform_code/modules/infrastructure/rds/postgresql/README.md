# PostgreSQL RDS Module

Creates an Amazon RDS PostgreSQL instance for the lab. Key settings such as instance class, database name and credentials are configurable through module variables.

## Usage
```hcl
module "postgresql" {
  source = "./modules/infrastructure/rds/postgresql"
  identifier = "lab-postgres"
  db_subnet_group_name = module.db_subnet_group.name
}
```
Make sure your IAM policies allow `rds:*` actions when applying this module.
