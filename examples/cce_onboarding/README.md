# CCE AWS Organization Onboarding

Terraform configuration to onboard an AWS Organization and all its member accounts into CyberArk Cloud Entitlements (CCE). This deploys IAM roles across the organization via CloudFormation StackSets and registers each member account with the CyberArk CCE API.

## Architecture

1. **Organization onboarding** -- The `cyberark/cce-organization/aws` module registers the AWS Organization with CyberArk and creates IAM roles in the management account for CCE scanning and SCA/SIA services.
2. **Account discovery** -- All member accounts are automatically discovered from the AWS Organization (management account is excluded).
3. **StackSet deployment** -- A service-managed CloudFormation StackSet deploys IAM roles (SCA and/or SIA) to every member account. Auto-deployment is enabled so new accounts receive the roles automatically.
4. **Account registration** -- Each discovered member account is registered with the CyberArk CCE API, associating it with the deployed IAM roles.

## Prerequisites

- Terraform >= 1.8.5
- AWS CLI configured with **management account** credentials
- A CyberArk Identity service user and token
- Trusted access enabled for CloudFormation StackSets (one-time setup):

```bash
aws organizations enable-aws-service-access \
  --service-principal member.org.stacksets.cloudformation.amazonaws.com

aws cloudformation activate-organizations-access
```

## Usage

1. Copy the example tfvars file and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Initialize and apply:

```bash
terraform init
terraform plan
terraform apply
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `idsec_service_user` | CyberArk Identity service user | `string` | -- | yes |
| `idsec_service_token` | CyberArk Identity service token | `string` | -- | yes |
| `aws_region` | AWS region for provider configuration | `string` | `us-east-2` | no |
| `organization_id` | AWS Organization ID (e.g., `o-1234567890`) | `string` | -- | yes |
| `management_account_id` | AWS Management Account ID (12-digit) | `string` | -- | yes |
| `organization_root_id` | AWS Organization root ID (e.g., `r-abcd`) | `string` | -- | yes |
| `display_name` | Display name for the organization in CCE | `string` | `My Org` | no |
| `enable_sca` | Enable Secure Cloud Access (SCA) | `bool` | `true` | no |
| `enable_sia` | Enable Secure Infrastructure Access (SIA) | `bool` | `false` | no |
| `sca_sso_enable` | Enable IAM Identity Center (SSO) integration for SCA | `bool` | `false` | no |
| `sca_sso_region` | AWS region where IAM Identity Center is configured | `string` | `null` | when `sca_sso_enable = true` |

## Outputs

| Name | Description |
|------|-------------|
| `org_onboarding_id` | CyberArk CCE organization onboarding ID |
| `cce_scan_role_arn` | IAM role ARN for CCE organization scanning |
| `sca_role_arn` | IAM role ARN for SCA in the management account |
| `dpa_role_arn` | IAM role ARN for SIA/DPA in the management account |
| `member_accounts` | Map of discovered member accounts (name, email, status) |
| `member_account_count` | Total number of member accounts |
| `stackset_id` | CloudFormation StackSet ID |
| `registered_accounts` | Map of member accounts registered with CCE |

## File Structure

```
cce_onboarding/
  main.tf                          # Providers, module, StackSet, and account registration
  variables.tf                     # Input variable definitions
  outputs.tf                       # Output definitions
  versions.tf                      # Terraform and provider version constraints
  terraform.tfvars.example         # Example variable values
  templates/
    member_account_iam.yaml        # CloudFormation template for member account IAM roles
```
