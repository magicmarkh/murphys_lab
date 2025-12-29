resource "idsec_cmgr_network" "main" {
  name        = var.network_name
}

resource "idsec_cmgr_pool" "main" {
  name               = var.pool_name
  description        = var.pool_description
  assigned_network_ids = [ idsec_cmgr_network.main.network_id ]
}

resource "idsec_cmgr_pool_identifier" "identifiers" {
  value = "*.mydomain.com"
  pool_id = idsec_cmgr_pool.main.pool_id
  type = "GENERAL_FQDN"
}