# RDS Modules

These modules deploy Amazon RDS databases used by the lab. Submodules are provided for MySQL and PostgreSQL engines.

## Usage
Choose the appropriate engine and include the module in your configuration:

```hcl
module "mysql" {
  source = "./modules/infrastructure/rds/mysql"
  identifier = "my-lab-db"
  # see variables.tf for more options
}
```

Provisioning RDS requires IAM privileges for `rds:*`. Database credentials should be stored securely, for example using the Secrets Manager module.
