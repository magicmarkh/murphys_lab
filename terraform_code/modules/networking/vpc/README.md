# VPC Module

This module builds the Virtual Private Cloud (VPC) that hosts the lab resources. It defines public and private subnets, route tables and internet gateways.

## Usage
```hcl
module "vpc" {
  source     = "./modules/networking/vpc"
  vpc_cidr   = "10.0.0.0/16"
}
```
Modify `variables.tf` to customize subnet CIDR blocks or Availability Zones as needed.
