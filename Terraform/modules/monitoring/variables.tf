variable "project" {
  description = "The project name"
  type        = string
  default     = "octabyte-assignment"
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "alert_email" {
  description = "The email address to receive alerts"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "The ARN suffix of the ALB target group"
  type        = string
}

variable "alb_arn_suffix" {
  description = "The ARN suffix of the Application Load Balancer"
  type        = string
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "log_group_name" {
  description = "The name of the CloudWatch log group for ECS tasks"
  type        = string
}

variable "ecs_service_name" {
  description = "The name of the ECS service"
  type        = string
}

