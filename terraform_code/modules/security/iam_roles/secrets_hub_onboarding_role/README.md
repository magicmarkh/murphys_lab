# Secrets Hub Onboarding Role

Creates a role used to enroll the lab account with AWS Secrets Hub. The role grants permissions required for the onboarding process such as creating resource shares and managing secrets.

## Usage
```hcl
module "secrets_hub_onboarding_role" {
  source = "./modules/security/iam_roles/secrets_hub_onboarding_role"
}
```
Only administrators performing the onboarding should assume this role.
