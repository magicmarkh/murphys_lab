# Automation Station Module

Provisions an EC2 instance preconfigured with Jenkins and Ansible for running automation tasks. The instance can pull code from version control and execute playbooks against the lab environment.

## Usage
```hcl
module "automation_station" {
  source  = "./modules/infrastructure/ec2_instances/automation_station"
  subnet_id = module.vpc.private_subnet_id
}
```
The IAM role assigned to this instance should allow it to assume other roles or access services as required by your automation workflows.
