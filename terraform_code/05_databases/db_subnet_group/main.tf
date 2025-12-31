resource "aws_db_subnet_group" "db" {
  name       = "${var.team_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.team_name}-db-subnet-group"
  }
}