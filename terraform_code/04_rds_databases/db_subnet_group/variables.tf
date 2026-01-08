variable "team_name" {
  description = "Name prefix for tagging and naming"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}
