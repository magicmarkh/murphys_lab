# Terraform Modules

This directory contains self‑contained Terraform modules that provide networking, security, and compute resources. Each module can be reused across environments and is documented in its own subfolder.

## Usage
Reference a module from your configuration using the `module` block. Example:

```hcl
module "vpc" {
  source = "./modules/networking/vpc"
  # see variables.tf in the module for available inputs
}
```

Modules help you organize infrastructure code and reduce duplication, which is especially helpful when managing IAM permissions across multiple resources.
