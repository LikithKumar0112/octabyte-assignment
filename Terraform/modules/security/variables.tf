variable "project" {
  description = "The project name"
  type        = string
  default     = "myproject"
}

variable "environment" {
  description = "The environment name"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "The VPC ID where the security groups will be created"
  type        = string
}

variable "app_port" {
  description = "The port on which the ECS task will listen"
  type        = number
  default     = 8080
}

