# AWS SIA Connector Module

Deploys the Secure Infrastructure Access (SIA) connector used for identity-aware access to the lab. The instance registers with the SIA service and must be able to reach the internet for onboarding.

## Usage
```hcl
module "sia_connector" {
  source = "./modules/infrastructure/ec2_instances/aws_sia_connector"
  subnet_id = module.vpc.private_subnet_id
}
```
Ensure that the IAM role attached to the instance allows the necessary SIA API calls and that outbound connectivity is permitted by the security group.
