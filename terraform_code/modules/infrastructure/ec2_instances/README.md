# EC2 Instance Modules

This folder contains submodules that launch different EC2 instances used by the lab (domain controllers, target hosts, and automation tooling). Each module configures IAM roles, security groups and user data as needed.

## Usage
Include the specific instance module you require. A simplified example:

```hcl
module "public_server" {
  source      = "./modules/infrastructure/ec2_instances/ec2_public_server"
  key_name    = module.key_pair.key_name
  vpc_subnet_id = module.vpc.public_subnet_id
}
```
Ensure your IAM user has `ec2:*` permissions and the ability to pass any roles created for the instance.
