# Wires every module together for one environment. Staging and production
# are separate roots (not terraform workspaces) with their own state files —
# smaller blast radius, explicit per-env config (Multi-AZ, deletion
# protection), no risk of applying to the wrong environment by mistake.

data "aws_caller_identity" "current" {}

module "network" {
  source      = "../../modules/network"
  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

module "security" {
  source      = "../../modules/security"
  project     = var.project
  environment = var.environment
  vpc_id      = module.network.vpc_id
  app_port    = var.app_port
}

module "alb" {
  source      = "../../modules/alb"
  project     = var.project
  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id
  vpc_id      = module.network.vpc_id
  public_subnet_ids       = module.network.public_subnet_ids
  alb_sg_id              = module.security.alb_sg_id
  app_port               = var.app_port
  deletion_protection     = var.enable_deletion_protection
}

module "rds" {
  source               = "../../modules/rds"
  project              = var.project
  environment          = var.environment
  private_subnet_ids   = module.network.private_subnet_ids
  db_sg_id             = module.security.db_sg_id
  instance_class       = var.db_instance_class
  multi_az             = var.db_multi_az
  backup_retention_days = var.db_backup_retention_days
  deletion_protection  = var.db_deletion_protection
  skip_final_snapshot  = var.db_skip_final_snapshot
}

module "ecs" {
  source                 = "../../modules/ecs"
  project                = var.project
  environment            = var.environment
  aws_region             = var.aws_region
  private_app_subnet_ids = module.network.private_app_subnet_ids
  app_sg_id              = module.security.app_sg_id
  target_group_arn       = module.alb.target_group_arn
  listener_arn           = module.alb.listener_arn
  app_image              = var.app_image
  app_port               = var.app_port
  desired_count          = var.desired_count
  min_capacity           = var.min_capacity
  max_capacity           = var.max_capacity
  log_retention_days     = var.log_retention_days
  db_address             = module.rds.db_address
  db_port                = module.rds.db_port
  db_name                = module.rds.db_name
  db_secret_arn          = module.rds.master_user_secret_arn
}

module "monitoring" {
  source                = "../../modules/monitoring"
  project               = var.project
  environment           = var.environment
  aws_region            = var.aws_region
  alert_email           = var.alert_email
  alb_arn_suffix        = module.alb.alb_arn_suffix
  ecs_cluster_name      = module.ecs.ecs_cluster_name
  ecs_service_name      = module.ecs.ecs_service_name
  ecs_log_group_name    = module.ecs.ecs_log_group_name
  db_instance_identifier = module.rds.db_instance_identifier
}


