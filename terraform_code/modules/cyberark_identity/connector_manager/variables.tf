variable "network_name" {
  description = "Name of the connector network"
  type        = string
}

variable "pool_name" {
  description = "Name of the connector manager pool"
  type        = string
}

variable "pool_description" {
  description = "Description of the connector manager pool"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to the connector manager pool"
  type = map(object({
    key   = string
    value = string
  }))
  default = {}
}

variable "pool_identifiers" {
  description = "List of identifiers to add to the connector manager pool"
  type        = list(string)
  default     = []
}
