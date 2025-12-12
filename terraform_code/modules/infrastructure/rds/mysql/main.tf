resource "random_password" "mysql_admin_password" {
  length  = 16
  special = true
  override_special = "/,@,\""
}

data "aws_rds_engine_version" "mysql_latest" {
  engine = "mysql"
}

resource "aws_db_instance" "mysql" {
  identifier             = var.identifier
  engine                 = "mysql"
  engine_version         = data.aws_rds_engine_version.mysql_latest.version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  username               = var.username
  password               = random_password.mysql_admin_password.result
  db_name                = var.db_name
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids

  publicly_accessible    = var.publicly_accessible
  multi_az               = false
  storage_type           = "gp2"
  skip_final_snapshot    = true

   tags = {
    Name  = "${var.identifier}"
    I_Owner = var.asset_owner_name
    I_Purpose = "Murphys Lab MySQL Target"
    CA_iScheduler = var.iScheduler
    CA_iSchedulerControl = "yes"
  }
}
