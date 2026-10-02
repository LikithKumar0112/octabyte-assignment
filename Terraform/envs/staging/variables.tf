variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., dev, staging, prod)"
  type        = string
}

variable "owner" {
  description = "The owner of the project"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT"
}

variable "app_port" {
  description = "The port on which the application will run"
  type        = number
}

variable "app_image" {
  description = "The Docker image for the application"
  type        = string
}

variable "desired_count" {
  description = "The desired number of ECS tasks"
  type        = number
}

variable "min_capacity" {
  description = "The minimum number of ECS tasks for auto-scaling"
  type        = number
}

variable "max_capacity" {
  description = "The maximum number of ECS tasks for auto-scaling"
  type        = number
}

variable "log_retention_days" {
  description = "The number of days to retain logs in CloudWatch"
  type        = number
}

variable "alb_deletion_protection" {
  description = "Whether to enable deletion protection for the ALB"
  type        = bool
  default     = false
}

variable "db_instance_class" {
  description = "The instance class for the RDS database"
  type        = string
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ for the RDS database"
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "The number of days to retain RDS backups"
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Whether to enable deletion protection for the RDS database"
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Whether to skip the final snapshot when deleting the RDS database"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "The email address to send alerts to"
  type        = string
}