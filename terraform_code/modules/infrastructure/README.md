# Infrastructure Modules

These modules provision the core resources of the lab including EC2 instances, RDS databases and Secrets Manager secrets. They are intended to be composed by the root configuration or other modules.

## Usage
Declare one of the submodules in your configuration and pass the required variables. For example:

```hcl
module "dc" {
  source = "./modules/infrastructure/ec2_instances/dc"
}
```

New IAM professionals should review the IAM policies attached to each module to understand the permissions required for provisioning.
