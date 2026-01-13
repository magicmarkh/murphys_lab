resource "aws_instance" "sia_aws_connector" {
  ami                         = var.linux_ami_id
  instance_type               = var.linux_ami_id_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.linux_security_group_ids]
  private_ip                  = var.sia_aws_connector_2_private_ip
  iam_instance_profile        = var.ec2_asm_instance_profile_name

  user_data = <<-EOF
    #!/bin/bash -xe

    SCRIPTS_DIR=/opt/sia
    mkdir -p "$SCRIPTS_DIR"

    # write init.sh
    cat > "$SCRIPTS_DIR/init.sh" << 'INIT_EOF'
    ${file("${path.module}/scripts/init.sh")}
    INIT_EOF
    chmod +x "$SCRIPTS_DIR/init.sh"

    # write register-connector.sh (with env vars)
    cat > "$SCRIPTS_DIR/register-connector.sh" << 'REG_EOF'
    export AWS_REGION="${var.region}"
    export PLATFORM_SECRET_ARN="${var.cyberark_secret_arn}"
    export IDENTITY_TENANT_ID="${var.identity_tenant_id}"
    export PLATFORM_TENANT_NAME="${var.platform_tenant_name}"
    export CONNECTOR_POOL_NAME="${var.connector_pool_name}"

    ${file("${path.module}/scripts/register-connector.sh")}
    REG_EOF
    chmod +x "$SCRIPTS_DIR/register-connector.sh"

    # run them
    "$SCRIPTS_DIR/init.sh" "${var.hostname}"
    "$SCRIPTS_DIR/register-connector.sh"
  EOF

  tags = {
    Name          = "${var.team_name}-aws-sia-connector-2"
    I_Owner       = var.asset_owner_name
    I_Purpose     = "Murphy's Lab SIA Connector"
    CA_iScheduler = var.iScheduler
  }

  lifecycle {
    ignore_changes = [tags, ami]
  }
}


resource "idsec_sia_access_connector" "connector2" {
  connector_type    = "AWS"
  connector_os      = "linux"
  connector_pool_id = "2fc8846d-2e29-4aa8-b8a2-d3b4738c8e5e"
  target_machine    = var.sia_aws_connector_2_private_ip
  username          = "ec2-user"
  private_key_path  = "key_pair/us-ent-east-key.pem"

  depends_on = [aws_instance.sia_aws_connector]
}