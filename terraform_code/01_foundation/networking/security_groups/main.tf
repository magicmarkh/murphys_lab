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
  description = "Allow RDP only from trusted IPs"
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
  description = "Allow RDP only from internal subnets"
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

resource "aws_security_group" "winrm_internal_flat" {
  name        = "${var.team_name}-internal-winrm-sg"
  description = "Allow WINRM only from internal subnets"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.internal_subnets
    content {
      description = "WINRM Terraform Port"
      from_port   = 5985
      to_port     = 5985
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
    Name  = "${var.team_name}-internal-flat-winrm-sg"
    Owner = var.asset_owner_name
  }
}

resource "aws_security_group" "https_internal_flat" {
  name        = "${var.team_name}-internal-flat-https-sg"
  description = "Allow HTTPS only from internal subnets"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.internal_subnets
    content {
      description = "HTTPS access"
      from_port   = 443
      to_port     = 443
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
    Name  = "${var.team_name}-internal-flat-https-sg"
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

locals {
  domain_controller_ports = [
    {
      description = "DNS TCP"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      name        = "DNS TCP"
    },
    {
      description = "DNS UDP"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      name        = "DNS UDP"
    },
    {
      description = "LDAP TCP"
      from_port   = 389
      to_port     = 389
      protocol    = "tcp"
      name        = "LDAP TCP"
    },
    {
      description = "LDAP UDP"
      from_port   = 389
      to_port     = 389
      protocol    = "udp"
      name        = "LDAP UDP"
    },
    {
      description = "Kerberos TCP"
      from_port   = 88
      to_port     = 88
      protocol    = "tcp"
      name        = "Kerberos TCP"
    },
    {
      description = "Kerberos UDP"
      from_port   = 88
      to_port     = 88
      protocol    = "udp"
      name        = "Kerberos UDP"
    },
    {
      description = "Global Catalog LDAP"
      from_port   = 3268
      to_port     = 3268
      protocol    = "tcp"
      name        = "Global Catalog LDAP"
    },
    {
      description = "Netlogon"
      from_port   = 445
      to_port     = 445
      protocol    = "tcp"
      name        = "NetLogon Port"
    },
    {
      description = "RPC Endpoint Mapper"
      from_port   = 135
      to_port     = 135
      protocol    = "tcp"
      name        = "RPC Endpoint Mapper"
    },
    {
      description = "Ephemeral Ports"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      name        = "Ephemeral Ports"
    },
    {
      description = "Kerberos Password Change Requests"
      from_port   = 464
      to_port     = 464
      protocol    = "tcp"
      name        = "Kerberos Password Change"
    },
    {
      description = "LDAPS from internal network"
      from_port   = 636
      to_port     = 636
      protocol    = "tcp"
      name        = "LDAPS"
    }
  ]
}

resource "aws_security_group" "domain_controller_sg" {
  name        = "domain-controller-sg"
  description = "Security Group for Windows 2016 Domain Controller (AD & DNS)"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.domain_controller_ports
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = var.internal_subnets
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "domain-controller-sg"
  }
}


locals {
  sia_windows_target = [
    {
      description = "SMB"
      from_port   = 445
      to_port     = 445
      protocol    = "tcp"
    },
    {
      description = "RPC Endpoint Mapper"
      from_port   = 135
      to_port     = 135
      protocol    = "tcp"
    }
  ]
}

resource "aws_security_group" "sia_windows_target_sg" {
  name        = "sia-windows-target-sg"
  description = "Ports required for SIA access to Windows RDP based targets"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = local.sia_windows_target
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = var.internal_subnets
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sia-windows-target-sg"
  }
}

resource "aws_security_group" "mysql_target_sg" {
  name        = "${var.team_name}-mysql-sg"
  description = "Allow MySQL from private subnets only"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL access from private subnets"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.team_name}-mysql-sg"
  }
}

resource "aws_security_group" "postgresql_target_sg" {
  name        = "${var.team_name}-postgresql-sg"
  description = "Allow PostgreSQL from private subnets only"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL access from private subnets"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.team_name}-postgresql-sg"
  }
}

# Add this to the security groups main.tf file

resource "aws_security_group" "mssql_target_sg" {
  name        = "${var.team_name}-mssql-sg"
  description = "Allow MSSQL from private subnets only"
  vpc_id      = var.vpc_id

  ingress {
    description = "MSSQL access from private subnets"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [var.private_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.team_name}-mssql-sg"
  }
}