output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_arn_suffix" {
  value = module.alb.alb_arn_suffix
}

output "alb_target_group_arn" {
  value = module.alb.alb_target_group_arn
}

output "target_group_arn_suffix" {
  description = "The ARN suffix of the target group"
  value       = module.alb.target_group_arn_suffix
}

output "alb_listener_arn" {
  value = module.alb.alb_listener_arn
}