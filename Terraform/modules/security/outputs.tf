output "alb_sg_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the ALB security group"
}

output "app_sg_id" {
  value       = aws_security_group.app.id
  description = "The ID of the ECS task security group"
}

output "db_sg_id" {
  value       = aws_security_group.db.id
  description = "The ID of the RDS security group"
}

