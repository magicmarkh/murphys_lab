# Windows Domain Accounts - User Guide

This Terraform configuration demonstrates a pattern for managing Windows domain accounts in CyberArk Privilege Cloud. Each account type is organized into its own safe with corresponding accounts, making it easy to expand and customize for your environment.

## Configuration Pattern

This module uses a **Safe + Accounts** pattern where:
- Each safe is defined alongside its accounts in the same file
- Accounts reference their safe using Terraform resource references
- Account types are separated into distinct variables for clarity
- Optional features like remote machine restrictions are configurable per account

## Example Account Types

The current implementation includes three account types, which can be customized or extended:

### Account Type 1: High-Privilege Accounts
Accounts with elevated privileges requiring strict controls.

**Example Safe:** `m-domain-admins`
**Example Platform:** `M-Windows-Domain-Admin`
**Example Use Cases:** Domain administrators, service accounts with domain rights

### Account Type 2: Server-Level Accounts
Accounts with server administrative privileges.

**Example Safe:** `m-domain-server-admins`
**Example Platform:** `M-Windows-Domain-User`
**Example Use Cases:** Server administrators, application service accounts

### Account Type 3: Standard User Accounts
Standard domain user accounts with limited privileges.

**Example Safe:** `m-domain-user`
**Example Platform:** `M-Windows-Domain-User`
**Example Use Cases:** JIT access accounts, temporary user accounts

## Configuration Files

- **`domain_accounts.tf`** - Safe and account resource definitions organized by account type
- **`variables.tf`** - Variable type definitions for each account type
- **`terraform.tfvars`** - Account configurations (credentials and settings)

## Adding New Accounts

Add accounts to `terraform.tfvars` under the appropriate account type variable:

```hcl
# High-privilege accounts
domain_admin_accounts = {
  account_key = {
    username        = "account_username"
    address         = "domain.local"
    platform_id     = "Platform-ID"
    secret          = "temporary_password"
    remote_machines = []  # Optional: ["ip1", "ip2"]
  }
}

# Server-level accounts
domain_server_admin_accounts = {
  account_key = {
    username        = "account_username"
    address         = "domain.local"
    platform_id     = "Platform-ID"
    secret          = "temporary_password"
    remote_machines = []  # Optional
  }
}

# Standard user accounts
domain_user_accounts = {
  account_key = {
    username        = "account_username"
    address         = "domain.local"
    platform_id     = "Platform-ID"
    secret          = "temporary_password"
    remote_machines = []  # Optional
  }
}
```

## Adding New Account Types

To add a new account type (e.g., database accounts, application accounts):

1. **Add variable definition** in `variables.tf`:
```hcl
variable "new_account_type_accounts" {
  type = map(object({
    username        = string
    address         = string
    platform_id     = string
    secret          = string
    remote_machines = optional(list(string), [])
  }))
  description = "Map of new account type accounts to manage"
  default     = {}
}
```

2. **Add safe and accounts** in `domain_accounts.tf`:
```hcl
# Safe
resource "idsec_pcloud_safe" "new-account-type-safe" {
  safe_name                = "safe-name"
  description              = "Description"
  number_of_days_retention = 7
}

# Accounts
resource "idsec_pcloud_account" "new_account_type_accounts" {
  for_each = var.new_account_type_accounts

  platform_id = each.value.platform_id
  username    = each.value.username
  address     = each.value.address
  secret      = each.value.secret
  safe_name   = idsec_pcloud_safe.new-account-type-safe.safe_name
  name        = "account-type-${each.value.username}"

  # Remote machine access restrictions (v0.1.17+ syntax)
  remote_machines                      = try(each.value.remote_machines, [])
  access_restricted_to_remote_machines = try(length(each.value.remote_machines) > 0, false)

  lifecycle {
    ignore_changes = [
      secret,
      name,
      account_id,
      created_time,
      category_modification_time,
      secret_type,
      platform_account_properties,
      remote_machines,                      # v0.1.17+: top-level attribute
      access_restricted_to_remote_machines, # v0.1.17+: top-level attribute
      status
    ]
  }
}
```

3. **Add accounts** in `terraform.tfvars`:
```hcl
new_account_type_accounts = {
  account1 = {
    username        = "username"
    address         = "domain.local"
    platform_id     = "Platform-ID"
    secret          = "temporary_password"
    remote_machines = []
  }
}
```

## Remote Machine Access

The `remote_machines` parameter restricts account usage to specific IP addresses or hostnames:
- When populated: `access_restricted_to_remote_machines` is automatically set to `true`
- When empty (`[]`): No access restrictions applied

**Example:**
```hcl
admin_account = {
  username        = "admin_user"
  address         = "domain.local"
  platform_id     = "Platform-ID"
  secret          = "password"
  remote_machines = ["192.168.1.10", "server1.domain.local"]
}
```

## Lifecycle Management

The following attributes are managed by CyberArk and ignored by Terraform after initial creation:

| Attribute | Managed By | Notes |
|-----------|------------|-------|
| `secret` | CyberArk CPM | Automatically rotated |
| `account_id` | CyberArk | Assigned at creation |
| `created_time` | CyberArk | Timestamp management |
| `remote_machines` | CyberArk | v0.1.17+: List of allowed remote machines |
| `access_restricted_to_remote_machines` | CyberArk | v0.1.17+: Boolean restriction flag |
| `platform_account_properties` | CyberArk Platform | Platform-specific settings |
| `status` | CyberArk | Account status |

**Important:** Terraform creates accounts with the specified `secret`, but CyberArk CPM manages password rotation thereafter. Do not update passwords through Terraform after initial creation.

## IDSec Provider v0.1.17 Migration

**Breaking Changes:**

The v0.1.17 provider changed the remote machine access syntax from a nested block to top-level attributes:

**Before (v0.1.12):**
```hcl
remote_machines_access = {
  remote_machines                      = ["ip1", "ip2"]
  access_restricted_to_remote_machines = true
}

lifecycle {
  ignore_changes = [secret, secret_management, remote_machines_access, status]
}
```

**After (v0.1.17):**
```hcl
remote_machines                      = ["ip1", "ip2"]
access_restricted_to_remote_machines = true

lifecycle {
  ignore_changes = [secret, remote_machines, access_restricted_to_remote_machines, status]
}
```

**Removed Attributes:**
- `secret_management` - CPM settings are now managed at the platform level only
- `remote_machines_access` (as a block) - Replaced with individual top-level attributes

**Migration Impact:**
- Remote machine restrictions functionality is preserved
- Existing accounts are not modified (syntax-only change)
- Terraform plan should show no changes after migration

## Account Naming Convention

Account names are automatically generated using the pattern:
```
{account-type-prefix}-{username}
```

Examples:
- `domain-admin-svc_reconcile`
- `domain-server-admin-svr_admin`
- `domain-user-svr_jit`

Customize the prefix in the `name` attribute of each account resource in `domain_accounts.tf`.

## Safe Protection

Critical safes can be protected from accidental deletion using the `prevent_destroy` lifecycle block:

```hcl
resource "idsec_pcloud_safe" "critical-safe" {
  safe_name                = "safe-name"
  description              = "Critical safe"
  number_of_days_retention = 7

  lifecycle {
    prevent_destroy = true
  }
}
```

To remove a protected safe:
1. Remove the `prevent_destroy` lifecycle block
2. Run `terraform apply`
3. Remove the safe resource and run `terraform apply` again

## Applying Changes

### Create or update accounts:
```bash
terraform plan
terraform apply
```

### Remove accounts:
1. Remove the account definition from `terraform.tfvars`
2. Run `terraform plan` to review
3. Run `terraform apply` to remove from CyberArk

### Remove account types:
1. Remove account entries from `terraform.tfvars`
2. Remove the variable from `variables.tf`
3. Remove the safe and account resources from `domain_accounts.tf`
4. Run `terraform plan` and `terraform apply`

## Current Implementation

This configuration currently manages:

- **3 Domain Admin Accounts** (`svc_reconcile`, `x_admin`, `z_admin`)
- **1 Domain Server Admin Account** (`svr_admin`)
- **1 Domain User Account** (`svr_jit`)

Across **3 safes** organized by privilege level.

## Extensibility

This pattern can be extended to support:

- **Additional account types:** Database accounts, application accounts, cloud accounts
- **Multiple domains:** Add domain-specific account types
- **Service accounts:** Separate variables for service vs. user accounts
- **Regional organization:** Group accounts by region or datacenter
- **Compliance tiers:** Organize by compliance requirements (PCI, SOX, etc.)

## Best Practices

1. **Organize by privilege level:** Group accounts with similar privilege levels into dedicated safes
2. **Use meaningful names:** Choose safe names and account type names that reflect their purpose
3. **Temporary passwords:** Set initial `secret` values that will be immediately rotated by CPM
4. **Least privilege:** Place accounts in the appropriate safe based on required access
5. **Remote restrictions:** Use `remote_machines` to limit where privileged accounts can be used
6. **Documentation:** Document the purpose of each account type in comments
7. **Regular reviews:** Periodically review accounts and remove unused entries
8. **Platform consistency:** Use consistent platform IDs within each account type

## Platform Selection

Choose CyberArk platforms based on account type and operating system:

**Windows Domain:**
- `M-Windows-Domain-Admin` - Domain administrator privileges
- `M-Windows-Domain-User` - Standard domain user

**Windows Local:**
- `M-Windows-Server-Local-Admin` - Local administrator accounts

**Unix/Linux:**
- `UnixSSH` - SSH access accounts
- `UnixSSHKeys` - SSH key-based access

Ensure platforms exist in your CyberArk environment before creating accounts.
