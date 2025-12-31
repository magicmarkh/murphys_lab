resource "random_password" "mssql_admin_password" {
  length  = 16
  special = false
  override_special = "!@#%^*()-_=+[]{}"
}

data "aws_rds_engine_version" "sqlserver_express_latest" {
  engine = "sqlserver-ex"
}

resource "aws_db_instance" "mssql" {
  identifier             = var.identifier
  engine                 = "sqlserver-ex"
  engine_version         = data.aws_rds_engine_version.sqlserver_express_latest.version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  username               = var.username
  password               = random_password.mssql_admin_password.result
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  domain_auth_secret_arn = var.domain_auth_secret_arn
  domain_dns_ips         = var.domain_dns_ips
  domain_ou              = var.domain_ou

  publicly_accessible     = var.publicly_accessible
  multi_az                = false
  storage_type            = "gp2"
  skip_final_snapshot     = true
  deletion_protection     = var.deletion_protection
  backup_retention_period = var.backup_retention

  # SQL Server Express specific settings
  license_model = "license-included"

  tags = {
    Name          = "${var.identifier}"
    I_Owner         = var.asset_owner_name
    I_Purpose     = "Murphys Lab MSSQL Target"
    CA_iScheduler = var.iScheduler
    CA_iSchedulerControl = "yes"
  }
}