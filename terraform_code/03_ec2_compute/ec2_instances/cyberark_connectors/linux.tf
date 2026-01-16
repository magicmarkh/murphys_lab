resource "aws_instance" "sia_linux_aws_connector" {
  ami                         = var.linux_ami_id
  instance_type               = var.linux_ami_id_instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.linux_security_group_ids]
  private_ip                  = var.sia_linux_private_ip
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
    "$SCRIPTS_DIR/init.sh" "${var.hostname}"
  
  EOF

  tags = {
    Name          = "${var.team_name}-linux-sia-connector"
    I_Owner       = var.asset_owner_name
    I_Purpose     = "Murphy's Lab Linux SIA Connector"
    CA_iScheduler = var.iScheduler
  }

  lifecycle {
    ignore_changes = [tags, ami]
  }
}


resource "idsec_sia_access_connector" "linux_connector" {
  connector_type    = "AWS"
  connector_os      = "linux"
  connector_pool_id = var.connector_pool_id
  target_machine    = var.sia_linux_private_ip
  username          = "ec2-user"
  private_key_path  = var.private_key_path
  depends_on        = [aws_instance.sia_linux_aws_connector]
}