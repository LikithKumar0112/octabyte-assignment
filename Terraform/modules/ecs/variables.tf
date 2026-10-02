variable "project" {
  description = "The project name"
  type        = string
  default     = "octabyte-assignment"
}

variable "environment" {
  description = "The environment name"
  type        = string
  default     = "shared"
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "private_app_subnet_ids" {
  description = "The private subnet IDs for the ECS service"
  type        = list(string)
}

variable "listener_arn" {
  description = "The ARN of the ALB listener"
  type        = string
}

variable "app_image" {
  description = "The Docker image for the ECS service"
  type        = string
}

variable "task_cpu" {
  description = "The CPU units for the ECS task"
  type        = string
}

variable "app_port" {
  description = "The port on which the application listens"
  type        = number
  default     = 8000

}

variable "task_memory" {
  description = "The memory for the ECS task"
  type        = string
}

variable "desired_count" {
  description = "The desired number of ECS tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "The minimum capacity for the ECS service"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "The maximum capacity for the ECS service"
  type        = number
  default     = 4
}

variable "log_retention_in_days" {
  description = "The number of days to retain logs in CloudWatch"
  type        = number
  default     = 14
}

variable "db_address" {
  description = "The address of the database"
  type        = string
}

variable "db_port" {
  description = "The port of the database"
  type        = number
}

variable "db_secret_arn" {
  description = "The ARN of the secret containing the database password"
  type        = string
}

variable "target_group_arn" {
  description = "The ARN of the target group for the ECS service"
  type        = string
}

variable "db_name" {
  description = "The name of the database which the app connects to"
  type        = string
}

variable "app_security_group_id" {
  description = "The security group ID for the ECS service"
  type        = string
}