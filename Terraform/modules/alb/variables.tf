variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "account_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8000
}

variable "enable_delete_protection" {
  description = "Enable delete protection for the ALB"
  type        = bool
  default     = false
}

variable "log_retention_in_days" {
  description = "Number of days to retain ALB logs"
  type        = number
  default     = 30
}