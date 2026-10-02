output "sns_topic_arn" {
  description = "ARN of the SNS topic for monitoring alerts"
  value       = aws_sns_topic.alerts.arn
}

output "application_dashboard_url" {
  description = "URL of the CloudWatch dashboard for application metrics"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.application.dashboard_name}"
}

output "infrastructure_dashboard_url" {
  description = "URL of the CloudWatch dashboard for infrastructure metrics"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.infrastructure.dashboard_name}"
}