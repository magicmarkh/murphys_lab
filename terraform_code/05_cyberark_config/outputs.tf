output "connector_network_id" {
  description = "ID of the connector network"
  value       = module.connector_pools.connector_network_id
}

output "connector_network_name" {
  description = "Name of the connector network"
  value       = module.connector_pools.connector_network_name
}

output "connector_manager_pool_id" {
  description = "ID of the connector manager pool"
  value       = module.connector_pools.connector_manager_pool_id
}

output "connector_manager_pool_name" {
  description = "Name of the connector manager pool"
  value       = module.connector_pools.connector_manager_pool_name
}
