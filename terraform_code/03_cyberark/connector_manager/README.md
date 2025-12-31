# CyberArk Identity Connector Manager Module

This Terraform module creates and manages CyberArk Identity Security Platform connector networks, connector manager pools, and pool identifiers.

## Resources Created

- `idsec_connector_network` - A connector network for organizing connectors
- `idsec_connector_manager_pool` - A connector manager pool associated with the network
- `idsec_connector_manager_pool_identifier` - Pool identifiers (created for each item in the list)

## Prerequisites

- CyberArk Identity tenant with appropriate permissions
- OAuth client credentials (client ID and secret) with connector management permissions
- Terraform >= 1.3.0
- CyberArk idsec provider configured

## Usage

```hcl
module "connector_manager" {
  source = "./modules/cyberark_identity/connector_manager"

  network_name        = "production-connector-network"
  network_description = "Connector network for production environment"
  pool_name           = "production-connector-pool"
  pool_description    = "Production connector manager pool"

  pool_identifiers = [
    "app-server-group",
    "database-group",
    "web-tier-group"
  ]

  tags = {
    environment = {
      key   = "Environment"
      value = "Production"
    }
    team = {
      key   = "Team"
      value = "Platform Engineering"
    }
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| network_name | Name of the connector network | `string` | n/a | yes |
| network_description | Description of the connector network | `string` | `""` | no |
| pool_name | Name of the connector manager pool | `string` | n/a | yes |
| pool_description | Description of the connector manager pool | `string` | `""` | no |
| pool_identifiers | List of identifiers to add to the connector manager pool | `list(string)` | `[]` | no |
| tags | Tags to apply to the connector manager pool | `map(object({ key = string, value = string }))` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| connector_network_id | ID of the created connector network |
| connector_network_name | Name of the created connector network |
| connector_manager_pool_id | ID of the created connector manager pool |
| connector_manager_pool_name | Name of the created connector manager pool |
| pool_identifiers | Map of pool identifiers created (identifier name -> ID) |

## Examples

### Basic Configuration

```hcl
module "connector_manager" {
  source = "./modules/cyberark_identity/connector_manager"

  network_name = "dev-network"
  pool_name    = "dev-pool"
}
```

### Advanced Configuration with Multiple Identifiers

```hcl
module "connector_manager" {
  source = "./modules/cyberark_identity/connector_manager"

  network_name        = "enterprise-connector-network"
  network_description = "Enterprise-wide connector network for all applications"
  pool_name           = "enterprise-connector-pool"
  pool_description    = "Main connector pool for enterprise applications"

  pool_identifiers = [
    "finance-systems",
    "hr-applications",
    "customer-portals",
    "internal-tools",
    "legacy-systems"
  ]

  tags = {
    cost_center = {
      key   = "CostCenter"
      value = "IT-Security"
    }
    compliance = {
      key   = "Compliance"
      value = "SOC2"
    }
    owner = {
      key   = "Owner"
      value = "security-team@example.com"
    }
  }
}
```

### Referencing Outputs

```hcl
# Use the pool ID in other resources
resource "idsec_connector" "example" {
  name = "my-connector"
  pool_id = module.connector_manager.connector_manager_pool_id
}

# Output the network details
output "network_info" {
  value = {
    network_id   = module.connector_manager.connector_network_id
    network_name = module.connector_manager.connector_network_name
    pool_id      = module.connector_manager.connector_manager_pool_id
  }
}
```

## Pool Identifiers

Pool identifiers are used to logically group and organize connectors within a pool. Each identifier in the `pool_identifiers` list will create a separate `idsec_connector_manager_pool_identifier` resource.

Common use cases for identifiers:
- Application groups (e.g., "web-apps", "databases")
- Environment tiers (e.g., "frontend", "backend", "middleware")
- Geographic regions (e.g., "us-east", "eu-west")
- Department or team names (e.g., "finance", "hr", "engineering")

## Tags

Tags are applied to the connector manager pool and can be used for:
- Cost allocation and tracking
- Resource organization
- Access control policies
- Compliance and auditing

Tags must be provided as a map of objects with `key` and `value` attributes:

```hcl
tags = {
  tag_name = {
    key   = "ActualTagKey"
    value = "ActualTagValue"
  }
}
```

## Notes

- The connector network must exist before the pool can be created (handled automatically by resource dependencies)
- Pool identifiers are created using `for_each` with `toset()` to ensure uniqueness
- All resources are managed through the CyberArk Identity Security Platform API via the idsec provider
- Changes to the network or pool name will force resource replacement

## Troubleshooting

### Error: "No declaration found for var.pool_identifiers"

Ensure you're passing the `pool_identifiers` variable when calling the module, or allow it to use the default empty list.

### Error: Pool creation fails

Verify that:
1. Your OAuth client has the necessary permissions to create connector pools
2. The network name doesn't already exist in your tenant
3. Your tenant URL and credentials are correctly configured in the idsec provider

### Identifiers not showing up

Check that:
1. The `pool_identifiers` variable is being passed correctly as a list of strings
2. The list contains valid identifier names (no duplicates, valid characters)
3. The pool was successfully created before attempting to create identifiers
