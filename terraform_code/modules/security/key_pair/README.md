# Key Pair Module

Handles creation or import of an SSH key pair used for connecting to EC2 instances. By default a new key is generated and stored locally.

## Usage
```hcl
module "key_pair" {
  source = "./modules/security/key_pair"
  key_name = "lab-key"
}
```
Keep the private key secure and restrict permissions to users who require SSH access.
