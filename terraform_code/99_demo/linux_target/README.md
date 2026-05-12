# Demo: Linux Target with CyberArk SSH Public Key Management

This demo deploys a Linux EC2 instance and uses the CyberArk Identity Security (idsec) provider to manage SSH public keys on the system.

## What This Demo Shows

1. **Linux EC2 Deployment**: Deploys an Amazon Linux 2023 instance
2. **CyberArk SSH Key Management**: Uses the `idsec_sia_ssh_public_key` resource to add a CyberArk-managed SSH public key to the Linux system

## Prerequisites

- Terraform >= 1.0
- AWS credentials configured via Conjur
- CyberArk Identity credentials configured via Conjur
- A CyberArk connector ID (update in terraform.tfvars)

## Configuration Steps

1. **Update terraform.tfvars**:
   - Set `connector_id` to your CyberArk connector ID
   - Verify all other values match your environment

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Plan the deployment**:
   ```bash
   terraform plan
   ```

4. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Resources Created

- **aws_instance.demo_linux_target**: Amazon Linux 2023 EC2 instance
- **idsec_sia_ssh_public_key.demo_linux_target_key**: CyberArk-managed SSH public key on the Linux system

## Important Notes

- The EC2 instance is created with the existing AWS key pair (`us-ent-east-key`)
- The `idsec_sia_ssh_public_key` resource adds an additional CyberArk-managed public key to the system
- The instance is placed in the private subnet and uses appropriate security groups

## Cleanup

To destroy all resources:
```bash
terraform destroy
```
