resource "aws_instance" "sia_linux_aws_connector" {
  count = var.linux_connector_count

  ami                         = var.linux_ami_id
  instance_type               = var.linux_ami_id_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.linux_security_group_ids]
  #iam_instance_profile        = var.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash -xe

    SCRIPTS_DIR=/opt/sia
    mkdir -p "$SCRIPTS_DIR"

    # write init.sh
    cat > "$SCRIPTS_DIR/init.sh" << 'INIT_EOF'
    ${file("${path.module}/scripts/init.sh")}
    INIT_EOF
    chmod +x "$SCRIPTS_DIR/init.sh"

    # run them
    "$SCRIPTS_DIR/init.sh" "${var.linux_connector_hostname_prefix}-${count.index + 1}"

  EOF

  tags = {
    Name          = "${var.team_name}-${var.linux_connector_name_prefix}-${count.index + 1}"
    I_Owner       = var.asset_owner_name
    I_Purpose     = "Murphy's Lab Linux SIA Connector"
    CA_iScheduler = var.iScheduler
  }

  lifecycle {
    ignore_changes = [tags, ami]
  }
}


resource "idsec_sia_access_connector" "linux_connector" {
  count = var.linux_connector_count

  connector_type       = "AWS"
  connector_os         = "linux"
  connector_pool_id    = var.connector_pool_id
  target_machine       = aws_instance.sia_linux_aws_connector[count.index].private_ip
  username             = "ec2-user"
  private_key_contents = var.private_key_contents
  depends_on           = [aws_instance.sia_linux_aws_connector]

  lifecycle {
    ignore_changes = [
      connector_id,
      password,
      private_key_contents,
      private_key_path
    ]
  }
}