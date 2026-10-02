output "alb_dns_name" {
  value = aws_alb.this.dns_name
}

output "alb_arn_suffix" {
  value = aws_alb.this.arn_suffix
}

output "target_group_arn" {
  value = aws_alb_target_group.this.arn
}

output "target_group_arn_suffix" {
  value = aws_alb_target_group.this.arn_suffix
}

output "listener_arn" {
  value = aws_alb_listener.this.arn
}