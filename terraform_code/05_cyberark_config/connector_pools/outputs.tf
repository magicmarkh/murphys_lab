output "connector_network_ids" {
  description = "Map of connector network IDs"
  value       = { for k, v in idsec_cmgr_network.networks : k => v.network_id }
}

output "connector_network_names" {
  description = "Map of connector network names"
  value       = { for k, v in idsec_cmgr_network.networks : k => v.name }
}

output "connector_manager_pool_id" {
  description = "ID of the connector manager pool"
  value       = idsec_cmgr_pool.main.pool_id
}

output "connector_manager_pool_name" {
  description = "Name of the connector manager pool"
  value       = idsec_cmgr_pool.main.name
}
