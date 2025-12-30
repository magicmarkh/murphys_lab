resource "random_password" "postgresql_admin_password" {
  length  = 16
  special = true
}

data "aws_rds_engine_version" "postgresql_latest" {
  engine = "postgres"
}

resource "aws_db_instance" "postgresql" {
  identifier              = "${var.team_name}-postgresql"
  engine                  = "postgres"
  engine_version          = data.aws_rds_engine_version.postgresql_latest.version
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  storage_encrypted       = true
  db_name                 = var.db_name
  username                = var.username
  password                = random_password.postgresql_admin_password.result
  db_subnet_group_name    = var.db_subnet_group_name
  vpc_security_group_ids  = var.vpc_security_group_ids
  publicly_accessible     = var.publicly_accessible
  deletion_protection     = var.deletion_protection
  backup_retention_period = var.backup_retention
  skip_final_snapshot     = true

    tags = {
    Name  = "${var.team_name}-postgresql"
    I_Owner = var.asset_owner_name
    I_Purpose = "Murphys Lab PostgreSql Target"
    CA_iScheduler = var.iScheduler
    CA_iSchedulerControl = "yes"
  }
}
