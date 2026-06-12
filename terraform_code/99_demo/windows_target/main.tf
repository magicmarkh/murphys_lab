# =====================================================================
# Demo Windows Target with CyberArk Password Vaulting
#
# This is a self-contained demonstration that shows:
# 1. Deploying a Windows EC2 instance
# 2. Setting a secure local Administrator password
# 3. Joining to Active Directory domain
# 4. Creating a CyberArk safe
# 5. Vaulting the Administrator password in CyberArk
#
# All components are in this single file for easy demonstration.
# =====================================================================

# =====================================================================
# Provider: Conjur - For retrieving secrets
# =====================================================================
provider "conjur" {
  appliance_url = var.conjur_appliance_url
  account       = var.conjur_account
  authn_type    = var.conjur_authn_type == "iam" ? "aws" : "api"

  # API key auth (laptop)
  login   = var.conjur_authn_type == "api" ? var.conjur_login : null
  api_key = var.conjur_authn_type == "api" ? var.conjur_api_key : null

  # IAM auth (EC2)
  service_id = var.conjur_authn_type == "iam" ? var.conjur_service_id : null
  host_id    = var.conjur_authn_type == "iam" ? var.conjur_host_id : null
}

# =====================================================================
# Data Sources: Conjur Secrets
# =====================================================================
data "conjur_secret" "aws_access_key" {
  count = var.conjur_authn_type == "api" ? 1 : 0
  name  = var.conjur_aws_access_key_path
}

data "conjur_secret" "aws_secret_key" {
  count = var.conjur_authn_type == "api" ? 1 : 0
  name  = var.conjur_aws_secret_key_path
}

data "conjur_secret" "domain_join_username" {
  name = var.conjur_domain_join_username_path
}

data "conjur_secret" "domain_join_password" {
  name = var.conjur_domain_join_password_path
}

data "conjur_secret" "identity_client_id" {
  name = var.conjur_identity_client_id_path
}

data "conjur_secret" "identity_client_secret" {
  name = var.conjur_identity_client_secret_path
}

# =====================================================================
# Provider: AWS
# =====================================================================
provider "aws" {
  region     = var.region
  # When using API auth, AWS creds come from Conjur secrets.
  # When using IAM auth, these are null and the provider uses the EC2 instance profile.
  access_key = one(data.conjur_secret.aws_access_key[*].value)
  secret_key = one(data.conjur_secret.aws_secret_key[*].value)
}

# =====================================================================
# Provider: CyberArk Identity Security (IDSec)
# =====================================================================
provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = data.conjur_secret.identity_client_id.value
  service_token = data.conjur_secret.identity_client_secret.value
}

# =====================================================================
# Data Sources: Remote State (Foundation and Security Layers)
# =====================================================================
data "terraform_remote_state" "foundation" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = var.foundation_state_key
    region = var.state_region
  }
}

data "terraform_remote_state" "security" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = var.security_state_key
    region = var.state_region
  }
}

# Get latest Windows Server 2022 AMI
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# =====================================================================
# Random Password for Local Administrator
# =====================================================================
resource "random_password" "admin_password" {
  length           = 24
  special          = true
  override_special = "!@#%^*()-_=+[]{}"
}

# =====================================================================
# EC2 Instance: Windows Server 2022
# =====================================================================
resource "aws_instance" "demo_target" {
  ami                         = data.aws_ami.windows_2022.id
  instance_type               = var.instance_type
  subnet_id                   = data.terraform_remote_state.foundation.outputs.private_subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids = [
    data.terraform_remote_state.foundation.outputs.rdp_internal_flat_sg_id,
    data.terraform_remote_state.foundation.outputs.winrm_internal_flat_sg_id,
    data.terraform_remote_state.foundation.outputs.sia_windows_target_sg_id
  ]

  # User data: Set password and enable WinRM
  user_data = <<-EOT
    <powershell>
    # Set known local Administrator password via EC2Launch
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Amazon\Ec2Launch\Settings" -Name "Password" -Value "Set"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Amazon\Ec2Launch\Settings" -Name "Random" -Value 0
    Set-LocalUser -Name "Administrator" -Password (ConvertTo-SecureString "${random_password.admin_password.result}" -AsPlainText -Force)

    # Enable WinRM (HTTP for lab)
    Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
    Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
    Enable-PSRemoting -Force
    </powershell>
  EOT

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name                 = "${var.team_name}-${var.hostname}"
    I_Owner              = var.asset_owner_name
    I_Purpose            = "Demo Windows Target - CyberArk Password Vaulting"
    CA_iScheduler        = var.iScheduler
    CA_iSchedulerControl = "yes"
  }

  lifecycle {
    ignore_changes = [ami, user_data]
  }
}

# =====================================================================
# Local Values: Escaped passwords for shell commands
# =====================================================================
locals {
  # Escape special characters in passwords for safe shell interpolation
  # This handles double quotes, backslashes, and dollar signs
  admin_password_escaped = replace(
    replace(
      replace(
        replace(random_password.admin_password.result, "\\", "\\\\"),
        "\"", "\\\""
      ),
      "$", "\\$"
    ),
    "'", "'\\''"
  )

  domain_password_escaped = replace(
    replace(
      replace(
        replace(data.conjur_secret.domain_join_password.value, "\\", "\\\\"),
        "\"", "\\\""
      ),
      "$", "\\$"
    ),
    "'", "'\\''"
  )
}

# =====================================================================
# Domain Join: Ansible Provisioner
# =====================================================================
resource "terraform_data" "domain_operations" {
  # Store values needed for destroy-time provisioner
  # These must be stored in triggers_replace to be available during destroy
  triggers_replace = {
    instance_id     = aws_instance.demo_target.id
    instance_ip     = aws_instance.demo_target.private_ip
    admin_password  = local.admin_password_escaped
    domain_user     = "${data.conjur_secret.domain_join_username.value}@${var.domain_name}"
    domain_password = local.domain_password_escaped
    domain_name     = var.domain_name
    domain_ou_path  = var.domain_ou_path
    hostname        = var.hostname
  }

  # Output ensures this resource is in the dependency graph
  input = aws_instance.demo_target.id

  # Create-time provisioner: Join domain
  provisioner "local-exec" {
    command = <<EOT
cd ../../../ansible && ansible-playbook \
  -i '${aws_instance.demo_target.private_ip},' \
  -e 'ansible_user=Administrator' \
  -e 'ansible_password="${local.admin_password_escaped}"' \
  -e 'ansible_connection=winrm' \
  -e 'ansible_port=5985' \
  -e 'ansible_winrm_scheme=http' \
  -e 'ansible_winrm_server_cert_validation=ignore' \
  -e 'hostname=${var.hostname}' \
  -e 'domain_join_username=${data.conjur_secret.domain_join_username.value}@${var.domain_name}' \
  -e 'domain_join_password="${local.domain_password_escaped}"' \
  -e 'domain_name=${var.domain_name}' \
  -e 'domain_ou_path=${var.domain_ou_path}' \
  playbooks/onboard_windows_connector.yml
EOT
  }

  # Destroy-time provisioner: Unjoin from domain
  # This will run BEFORE the instance is destroyed if proper order is followed
  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
echo "==================== DOMAIN UNJOIN STARTING ===================="
echo "Target IP: ${self.triggers_replace.instance_ip}"
echo "Hostname: ${self.triggers_replace.hostname}"
echo "Connecting as: local Administrator account"
echo "==============================================================="

cd ../../../ansible && ansible-playbook \
  -i '${self.triggers_replace.instance_ip},' \
  -e 'ansible_user=Administrator' \
  -e 'ansible_password="${self.triggers_replace.admin_password}"' \
  -e 'ansible_connection=winrm' \
  -e 'ansible_port=5985' \
  -e 'ansible_winrm_scheme=http' \
  -e 'ansible_winrm_server_cert_validation=ignore' \
  -e 'domain_admin_user=${self.triggers_replace.domain_user}' \
  -e 'domain_admin_password="${self.triggers_replace.domain_password}"' \
  -e 'domain_name=${self.triggers_replace.domain_name}' \
  playbooks/unjoin_domain.yml

UNJOIN_RESULT=$?
if [ $UNJOIN_RESULT -eq 0 ]; then
  echo "==================== DOMAIN UNJOIN SUCCESSFUL ===================="
else
  echo "==================== DOMAIN UNJOIN FAILED (exit code: $UNJOIN_RESULT) ===================="
  echo "WARNING: Instance will remain joined to domain!"
  exit $UNJOIN_RESULT
fi
EOT

    # Make failures visible - do NOT continue on failure
    # This ensures you know if unjoin fails
    on_failure = fail
  }

  # Explicit dependency: domain operations depend on instance existing
  depends_on = [aws_instance.demo_target]
}


# =====================================================================
# CyberArk Safe: For storing the Administrator password
# =====================================================================
resource "idsec_pcloud_safe" "demo_target_safe" {
  safe_name                = var.safe_name
  description              = var.safe_description
  number_of_days_retention = var.safe_retention_days

  depends_on = [aws_instance.demo_target]  # Ensure instance creation is successful before creating a safe to vault account
}

# =====================================================================
# CyberArk Account: Vault the Administrator password
# =====================================================================
resource "idsec_pcloud_account" "demo_target_admin" {
  platform_id = var.platform_id
  username    = "Administrator"
  address     = "${var.hostname}.${var.domain_name}"
  secret      = random_password.admin_password.result  # Actual password set on the server
  safe_name   = idsec_pcloud_safe.demo_target_safe.safe_name
  name        = "${var.hostname}-admin"

  depends_on = [idsec_pcloud_safe.demo_target_safe] # Ensure safe is created before vaulting account

  lifecycle {
    ignore_changes = [
      secret,                         # CPM rotates passwords after initial creation
      name,                           # CyberArk manages naming
      account_id,                     # Assigned by CyberArk
      secret_type,                    # Computed by CyberArk
      platform_account_properties    # Platform-specific settings
    ]
  }
}
