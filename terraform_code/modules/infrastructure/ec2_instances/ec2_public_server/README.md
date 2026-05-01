# Public Server Module

Launches an EC2 instance with a public IP address. Useful for demo servers or jump hosts. The instance is placed in a public subnet and optionally associated with an IAM role for management access.

## Usage
```hcl
module "public_server" {
  source     = "./modules/infrastructure/ec2_instances/ec2_public_server"
  key_name   = module.key_pair.key_name
  subnet_id  = module.vpc.public_subnet_id
}
```
A security group allowing inbound access should also be attached. The deploying IAM identity requires `ec2:*` permissions.
