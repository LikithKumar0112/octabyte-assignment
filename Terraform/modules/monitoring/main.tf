#Alarams, SNS, email, 2 cloudwatch dashboards

locals {
  name_prefix = "${var.project}-${var.environment}"
}

variable "db_instance_identifier" {
  description = "RDS DB instance identifier for the monitoring alarms"
  type        = string
}

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

#Alarams

resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  alarm_name          = "${local.name_prefix}-alb-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "5"
  evaluation_periods  = "1"
  datapoints_to_alarm = "1"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "error_rate"
    expression  = "(m5xx / IF(mreq > 0, mreq, 1)) * 100"
    label       = "ALB 5xx Error Rate"
    return_data = true
  }

  metric_query {
    id = "m5xx"
    metric {
      metric_name = "HTTPCode_Target_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = "60"
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_name
      }
    }
  }

  metric_query {
    id = "mreq"
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = "60"
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_p95_latency" {
  alarm_name          = "${local.name_prefix}-alb-p95-latency"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  extended_statistic = "p95"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = "1"
  period              = "300"
  evaluation_periods  = "2"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${local.name_prefix}-unhealthy-targets"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnhealthyHostCount"
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  period              = "60"
  evaluation_periods  = "1"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${local.name_prefix}-ecs-cpu-high"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  dimensions          = { ClusterName = var.ecs_cluster_name, ServiceName = var.ecs_service_name }
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  period              = 300
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = var.db_instance_identifier }
  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 80
  period              = 300
  evaluation_periods  = 2
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${local.name_prefix}-rds-free-storage-low"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = { DBInstanceIdentifier = var.db_instance_identifier }
  statistic           = "Minimum"
  comparison_operator = "LessThanThreshold"
  threshold           = 2147483648 # 2 GB in bytes
  period              = 300
  evaluation_periods  = 1
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

#dashboard 1

resource "aws_cloudwatch_dashboard" "application" {
    dashboard_name = "${local.name_prefix}-application-dashboard"
    dashboard_body = jsonencode({
        widgets = [
        {
            type = "metric"
            x    = 0
            y    = 0
            width = 12
            height = 6
            properties = {
            metrics = [
                [ "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix ],
                [ ".", "RequestCount", ".", "." ]
            ]
            view       = "timeSeries"
            stacked    = false
            region     = var.region
            title      = "ALB 5xx Error Rate"
            }
        },
        {
            type = "metric"
            x    = 0
            y    = 6
            width = 12
            height = 6
            properties = {
            metrics = [
                [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { "stat": "p95" } ]
            ]
            view       = "timeSeries"
            stacked    = false
            region     = var.region
            title      = "ALB P95 Latency"
            }
        }
        ]
    })
}

#dashboard 2

resource "aws_cloudwatch_dashboard" "infrastructure" {
    dashboard_name = "${local.name_prefix}-infrastructure-dashboard"
    dashboard_body = jsonencode({
        widgets = [
        {
            type = "metric"
            x    = 0
            y    = 0
            width = 12
            height = 6
            properties = {
            metrics = [
                [ "AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, "ServiceName", var.ecs_service_name ]
            ]
            view       = "timeSeries"
            stacked    = false
            region     = var.region
            title      = "ECS CPU Utilization"
            }
        },
        {
            type = "metric"
            x    = 0
            y    = 6
            width = 12
            height = 6
            properties = {
            metrics = [
                [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.db_instance_identifier ],
                [ ".", "FreeStorageSpace", ".", "." ]
            ]
            view       = "timeSeries"
            stacked    = false
            region     = var.region
            title      = "RDS CPU and Free Storage Space"
            }
        }
        ]
    })
}

#saved logs insight queries

resource "aws_cloudwatch_query_definition" "errors_last_hour" {
  name           = "${local.name_prefix}-errors-last-hour"
  log_group_names = [var.log_group_name]
  query_string = <<QUERY
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
QUERY
}

resource "aws_cloudwatch_query_definition" "slow_requests_last_hour" {
  name           = "${local.name_prefix}-slow-requests-last-hour"
  log_group_names = [var.log_group_name]
  query_string = <<QUERY
fields @timestamp, @message
| filter @message like /SLOW/
| sort @timestamp desc
| limit 100
QUERY
}

resource "aws_cloudwatch_query_definition" "requests_by_status" {
  name           = "${local.name_prefix}-requests-by-status"
  log_group_names = [var.log_group_name]
  query_string = <<QUERY
fields @timestamp, @message
| filter @message like /200|404|500/
| sort @timestamp desc
| limit 100
QUERY
}