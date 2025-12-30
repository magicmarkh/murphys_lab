output "connector_network_id" {
  description = "ID of the connector network"
  value       = idsec_cmgr_network.main.network_id
}

output "connector_network_name" {
  description = "Name of the connector network"
  value       = idsec_cmgr_network.main.name
}

output "connector_manager_pool_id" {
  description = "ID of the connector manager pool"
  value       = idsec_cmgr_pool.main.pool_id
}

output "connector_manager_pool_name" {
  description = "Name of the connector manager pool"
  value       = idsec_cmgr_pool.main.name
}
