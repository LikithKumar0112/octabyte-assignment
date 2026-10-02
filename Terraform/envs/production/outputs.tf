output "alb_url" {
  value = "http://${module.alb.alb_dns_name}"
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "task_definition_family" {
  value = module.ecs.task_definition_family
}

output "rds_endpoint" {
  value = module.rds.db_address
}

output "db_secret_arn" {
  value = module.rds.master_user_secret_arn
}

output "application_dashboard_url" {
  value = module.monitoring.application_dashboard_url
}

output "infrastructure_dashboard_url" {
  value = module.monitoring.infrastructure_dashboard_url
}
