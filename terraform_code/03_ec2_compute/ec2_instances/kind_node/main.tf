resource "aws_instance" "kind_node" {
  ami                         = var.linux_ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id
  associate_public_ip_address = false
  key_name                    = var.key_name
  vpc_security_group_ids      = [var.linux_security_group_ids]
  private_ip                  = var.kind_node_private_ip
  disable_api_termination     = true

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash -xe
    hostnamectl set-hostname "${var.kind_node_hostname}"
  EOF

  tags = {
    Name                 = "${var.team_name}-kind-1"
    I_Owner              = var.asset_owner_name
    I_Purpose            = "Murphys Lab Kind Kubernetes Node"
    CA_iScheduler        = var.iScheduler
    CA_iSchedulerControl = "yes"
  }

  lifecycle {
    ignore_changes  = [tags, ami, user_data]
    prevent_destroy = true
  }
}

resource "null_resource" "setup_kind" {
  depends_on = [aws_instance.kind_node]

  provisioner "local-exec" {
    command = <<EOT
# Write private key to temp file
KEYFILE=$(mktemp)
echo '${var.private_key_contents}' > "$KEYFILE"
chmod 600 "$KEYFILE"

# Wait for SSH to become available
echo "Waiting for SSH on ${aws_instance.kind_node.private_ip}..."
for i in $(seq 1 30); do
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$KEYFILE" ec2-user@${aws_instance.kind_node.private_ip} "echo ready" && break
  echo "Attempt $i/30 - waiting 10s..."
  sleep 10
done

# Run Ansible playbook
cd ../../ansible && ansible-playbook \
  -i '${aws_instance.kind_node.private_ip},' \
  -e 'ansible_user=ec2-user' \
  --private-key="$KEYFILE" \
  playbooks/setup_kind_node.yml

# Cleanup
rm -f "$KEYFILE"
EOT
  }
}
