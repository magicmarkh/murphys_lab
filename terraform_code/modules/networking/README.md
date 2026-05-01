# Networking Modules

This section contains modules that configure the network layout for the lab. Modules are provided for creating the VPC, database subnet groups and security groups.

## Usage
Include the required networking modules in your root configuration:
```hcl
module "vpc" {
  source = "./modules/networking/vpc"
}
```
Proper networking design is key for controlling which IAM roles and services can communicate with one another.
