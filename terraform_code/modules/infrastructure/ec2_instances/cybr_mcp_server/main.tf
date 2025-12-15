// modules/cybr_mcp_server/main.tf

#create the instance
resource "aws_instance" "cybr_mcp_server" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.vpc_security_group_ids]
  private_ip                  = var.private_ip_address
  iam_instance_profile        = var.ec2_asm_instance_profile_name

  user_data = <<-EOF
    #!/bin/bash -xe
    
    # Set environment variables for SIA configuration
    export AWS_REGION="${var.region}"
    export PLATFORM_SECRET_ARN="${var.cyberark_secret_arn}"
    export IDENTITY_TENANT_ID="${var.identity_tenant_id}"
    export PLATFORM_TENANT_NAME="${var.platform_tenant_name}"
    export WORKSPACE_ID="${var.workspace_id}"
    export WORKSPACE_TYPE="${var.workspace_type}"
    export USERNAME_DOMAIN="${var.username_domain}"

    # Create and run the init script
    cat > /tmp/init.sh << 'INIT_EOF'
    ${file("${path.module}/scripts/init.sh")}
    INIT_EOF
    chmod +x /tmp/init.sh
    
    # Run the combined init script with hostname parameter
    /tmp/init.sh "${var.mcp_server_hostname}"
  EOF

  tags = {
    Name  = "${var.team_name}-cybr-mcp-server"
    I_Owner = var.asset_owner_name
    I_Purpose = "Murphys Lab CyberArk MCP Server"
    CA_iScheduler = var.iScheduler
    CA_iSchedulerControl = "yes"
  }

  lifecycle {
    ignore_changes = [ tags ]
  }
}