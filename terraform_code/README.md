# Terraform Code

This directory holds the main configuration used to deploy the lab's AWS environment. New IAM professionals can explore how modules are composed to provision networking, compute, and security resources.

## Usage
1. Configure your AWS credentials with sufficient permissions for IAM and resource creation.
2. Run `terraform init` to download the required providers.
3. Review the variables in `terraform.tfvars` and adjust values for your environment.
4. Execute `terraform apply` to create the infrastructure.

The `modules` folder contains reusable building blocks referenced by this top level configuration.
