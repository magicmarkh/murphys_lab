# Target Hosts Module

Deploys EC2 instances that act as target machines within the lab. Targets can be Windows or Linux and typically host demo applications used during training.

## Usage
```hcl
module "targets" {
  source = "./modules/infrastructure/ec2_instances/targets"
  instance_count = 2
  subnet_id      = module.vpc.private_subnet_id
}
```
An IAM role with `ec2:*` permissions is required to launch and configure these instances.
