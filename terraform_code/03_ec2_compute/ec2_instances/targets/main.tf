resource "aws_instance" "linux_target_1" {
  ami                         = var.linux_ami_id
  instance_type               = var.linux_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.linux_security_group_ids]
  private_ip                  = var.linux_target_1_private_ip
  iam_instance_profile        = var.ec2_tf_automation_instance_profile_name
  disable_api_termination     = true

  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }

  user_data                   = <<-EOF
    #!/bin/bash -xe

    SCRIPTS_DIR=/opt/sia
    mkdir -p "$SCRIPTS_DIR"

    # write set-hostname.sh
    cat > "$SCRIPTS_DIR/set-hostname.sh" << 'INIT_EOF'
    ${file("${path.module}/scripts/set-hostname.sh")}
    INIT_EOF
    chmod +x "$SCRIPTS_DIR/set-hostname.sh"

    # write configure-endpoint.sh (with env vars)
    cat > "$SCRIPTS_DIR/configure-endpoint.sh" <<- 'CONF_EOF'
    #!/usr/bin/env bash
    set -xe

    export IDENTITY_CLIENT_ID="${var.identity_client_id}"
    export IDENTITY_CLIENT_SECRET="${var.identity_client_secret}"
    export IDENTITY_TENANT_ID="${var.identity_tenant_id}"
    export PLATFORM_TENANT_NAME="${var.platform_tenant_name}"
    export WORKSPACE_ID="${var.workspace_id}"
    export WORKSPACE_TYPE="${var.workspace_type}"

    ${file("${path.module}/scripts/configure-endpoint.sh")}
    CONF_EOF
    chmod +x "$SCRIPTS_DIR/configure-endpoint.sh"

    # run them
    "$SCRIPTS_DIR/set-hostname.sh" "${var.linux_target_1_hostname}"
    "$SCRIPTS_DIR/configure-endpoint.sh"
  EOF
  tags = {
    Name                 = "${var.team_name}-linux-target-1"
    I_Owner              = var.asset_owner_name
    I_Purpose            = "Murphys Lab Linux Target System"
    CA_iScheduler        = var.iScheduler
    CA_iSchedulerControl = "yes"
  }

  lifecycle {
    ignore_changes = [tags, ami, user_data]
    prevent_destroy = true
  }
}


resource "aws_instance" "target_windows_server" {
  ami                         = var.windows_ami_id
  instance_type               = var.windows_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = var.windows_security_group_ids
  private_ip                  = var.windows_target_1_private_ip
  disable_api_termination     = true

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name                 = "${var.team_name}-windows-target-1"
    I_Owner              = var.asset_owner_name
    I_Purpose            = "Murphys Lab Windows Target"
    CA_iScheduler        = var.iScheduler
    CA_iSchedulerControl = "yes"
  }

  lifecycle {
    ignore_changes = [tags, ami]
    prevent_destroy = true
  }
}
