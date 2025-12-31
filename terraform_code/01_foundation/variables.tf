# ===========================
# Common Variables
# ===========================
variable "asset_owner_name" {
  description = "Name of the human that the cloud team can contact with questions"
  type        = string
}

variable "region" {
  description = "AWS cloud region for the deployment"
  type        = string
  default     = "us-east-2"
}

variable "team_name" {
  description = "Cloud naming identifier"
  type        = string
  default     = "us-ent-east"
}

# ===========================
# VPC Variables
# ===========================
variable "private_subnet_az" {
  description = "AWS identifier for the private subnet AZ"
  type        = string
  default     = "us-east-2b"
}

variable "public_subnet_az" {
  description = "AWS identifier for the public subnet AZ"
  type        = string
  default     = "us-east-2a"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for your public subnet"
  type        = string
  default     = "192.168.50.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for your private subnet"
  type        = string
  default     = "192.168.20.0/24"
}

variable "domain_name" {
  description = "Name of the domain to join connectors to"
  type        = string
}

variable "dc1_private_ip" {
  description = "Private IP of DC1 (used as DNS server IP)"
  type        = string
}

# ===========================
# Security Group Variables
# ===========================
variable "trusted_ips" {
  description = "Trusted public IPs"
  type        = list(string)
}
