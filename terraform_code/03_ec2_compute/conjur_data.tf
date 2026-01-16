# =====================================================================
# Conjur Data Sources - Shared credentials for EC2 resources
# =====================================================================
# These data sources retrieve secrets from Conjur that can be used
# across multiple EC2 instance types (connectors, targets, etc.)

# Example: Domain join credentials
data "conjur_secret" "domain_join_username" {
  name = var.conjur_domain_join_username_path
}

data "conjur_secret" "domain_join_password" {
  name = var.conjur_domain_join_password_path
}

# Add additional Conjur secret data sources here as needed
