locals {
  project     = var.project
  environment = var.environment
  name_prefix = "${local.project}-${local.environment}"
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.project}-${local.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name        = "${local.project}-${local.environment}-db-subnet-group"
    Environment = local.environment
    Project     = local.project
  }
}

resource "aws_db_parameter_group" "this" {
  name        = "${local.project}-${local.environment}-db-parameter-group"
  family      = "postgres16"
  description = "Custom parameter group for ${local.project}-${local.environment}"

  parameter {
    name  = "log_min_duration_statement"
    value = "500"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name        = "${local.project}-${local.environment}-db-parameter-group"
    Environment = local.environment
    Project     = local.project
  }
}

resource "aws_db_instance" "this" {
  identifier                  = "${local.name_prefix}-db"
  engine                      = "postgres"
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  max_allocated_storage       = var.max_allocated_storage
  storage_type                = "gp3"
  storage_encrypted           = true
  db_name                     = var.db_name
  username                    = var.db_username
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.this.name
  vpc_security_group_ids      = [var.db_sg_id]
  parameter_group_name        = aws_db_parameter_group.this.name
  publicly_accessible         = false
  multi_az                    = var.multi_az
  backup_retention_period     = var.backup_retention_days
  backup_window               = "17:00-17:30" # 22:30-23:00 IST, off-peak
  maintenance_window          = "sun:18:00-sun:19:00"
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = var.skip_final_snapshot
  final_snapshot_identifier   = var.skip_final_snapshot ? null : "${local.name_prefix}-final-snapshot"
  copy_tags_to_snapshot       = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true
  auto_minor_version_upgrade      = true

  tags = { Name = "${local.name_prefix}-db" }

}

