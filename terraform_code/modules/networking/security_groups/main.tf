resource "aws_security_group" "ssh_from_trusted_ips" {
  name        = "${var.team_name}-trusted-external-ssh-sg"
  description = "Allow SSH only from trusted IPs"
  vpc_id      = var.vpc_id

dynamic "ingress" {
  for_each = var.trusted_ips
  content {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ingress.value]
  }
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.team_name}-trusted-ip-ssh-sg"
    Owner = var.asset_owner_name
  }
}

resource "aws_security_group" "rdp_from_trusted_ips" {
  name        = "${var.team_name}-trusted-external-rdp-sg"
  description = "Allow SSH only from trusted IPs"
  vpc_id      = var.vpc_id

dynamic "ingress" {
  for_each = var.trusted_ips
  content {
    description = "rdp access"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [ingress.value]
  }
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.team_name}-trusted-ip-rdp-sg"
    Owner = var.asset_owner_name
  }
}

resource "aws_security_group" "ssh_internal_flat" {
  name        = "${var.team_name}-internal-flat-ssh-sg"
  description = "Allow SSH only from internal subnets"
  vpc_id      = var.vpc_id

dynamic "ingress" {
  for_each = var.internal_subnets
  content {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ingress.value]
  }
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.team_name}-trusted-ip-ssh-sg"
    Owner = var.asset_owner_name
  }
}

resource "aws_security_group" "rdp_internal_flat" {
  name        = "${var.team_name}-internal-flat-rdp-sg"
  description = "Allow SSH only from internal subnets"
  vpc_id      = var.vpc_id

dynamic "ingress" {
  for_each = var.internal_subnets
  content {
    description = "RDP access"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [ingress.value]
  }
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.team_name}-internal-flat-rdp-sg"
    Owner = var.asset_owner_name
  }
}

resource "aws_security_group" "jenkins_8080" {
  name        = "${var.team_name}-jenkins-8080-sg"
  description = "8080"
  vpc_id      = var.vpc_id

dynamic "ingress" {
  for_each = var.internal_subnets
  content {
    description = "Jenkins Web Access"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [ingress.value]
  }
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.team_name}-jenkins-8080-sg"
    Owner = var.asset_owner_name
  }
}
