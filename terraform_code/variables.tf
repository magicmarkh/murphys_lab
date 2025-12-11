variable "asset_owner_name" {
  description = "Name of the human that the cloud team can contact with questions"
  type = string
}

variable "region" {
  description = "AWS cloud region for the deployment"
  default = "us-east-2"
  type = string
}

variable "team_name" {
  description = "cloud naming identifier"
  default = "us-ent-east"
  type = string
}

variable "private_subnet_az" {
  description = "AWS identifier for the private subnet AZ"
  default = "us-east-2b"
  type = string
}

variable "public_subnet_az" {
  description = "AWS identifier for the public subnet AZ"
  default = "us-east-2a"
  type = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for your public subnet"
  default = "192.168.50.0/24"
  type = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for your private subnet"
  default = "192.168.20.0/24"
  type = string
}

variable "amzn_linux_ami_id" {
  description = "ami id for amazon linux ec2"
  type = string
  default = "ami-058a8a5ab36292159"
}

variable "amzn_windows_server_ami_id" {
  description = "ami id for amazon windows ec2"
  type = string
  default = "ami-0f92a5908d7b0f379"
}

variable "iScheduler" {
  description = "use if the system should be shutdown nightly"
  type = string
  default = "US_E_office"
}

variable "trusted_ips" {
  description = "trusted public IP's"
  type = list(string)
}

variable "automation_station_private_ip" {
  description = "private ip of automation station"
  type = string
}

variable "dc1_private_ip" {
  description = "private ip of dc1"
  type = string
}

variable "linux_target_1_private_ip" {
  description = "private ip of linux target 1"
  type = string
}

variable "windows_target_1_private_ip" {
  description = "private ip of windows target 1"
  type = string
}

variable "connector_1_private_ip" {
  description = "private ip of windows target 1"
  type = string
}

variable "sia_aws_connector_1_private_ip" {
  description = "private ip of windows target 1"
  type = string
}

variable "domain_join_username" {
  description = "Domain join username (e.g., CORP\\joinuser)"
  type        = string
}

variable "domain_join_password" {
  description = "Domain join password"
  type        = string
  sensitive   = true
}

variable "domain_join_secret_name" {
  description = "Secrets Manager secret name"
  type        = string
}

variable "CyberArkSecretsHubRoleARN" {
  description = "The Secrets Hub tenant role ARN which will be trusted by this role - get this from the cyberark tenant in secrets hub settings."
  type        = string
}

variable "connector_pool_name" {
  description = "Name of the connector pool you're adding the connector to"
  type        = string
}

variable "cyberark_secret_arn" {
  description = "arn of the identity service account. Used if retrieving the service account from ASM."
  type        = string
}

variable "identity_tenant_id" {
  description = "your cyberark tenant id. Example: 'https://abc123.id.cyberark.cloud' woud be abc123"
  type        = string
}

variable "platform_tenant_name" {
  description = "name of your cyberark tenant. Example: 'https://acme.cyberark.cloud' would be acme"
  type        = string
}

variable "workspace_type" {
  description = "CSP identifier. AWS, Azure, or GCP"
  type = string
  default = "AWS"
}

variable "linux_target_1_hostname" {
  description = "name of the target demo system for linux"
  type = string
}

variable "domain_join_secret_arn" {
  description = "ARN of the secret stored in ASM for domain join operations"
  type = string
}

variable "connector_2_private_ip" {
  description = "private IP for connector 2"
  type = string
}

variable "domain_name" {
  description = "name of the domain to join connectors to"
  type = string
}

variable "connector_2_hostname" {
  description = "hostname of connector 2"
  type = string
}

variable "enable_mssql_domain_join" {
  description = "Enable domain join for MSSQL RDS instance"
  type        = bool
  default     = true
}

variable "mssql_domain_join_arn" {
  description = "arn for mssql service account"
  type        = string
  default     = null
}

variable "mssql_domain_ou" {
  description = "Organizational Unit (OU) in AD for RDS MSSQL (optional)"
  type        = string
  default     = null
}

