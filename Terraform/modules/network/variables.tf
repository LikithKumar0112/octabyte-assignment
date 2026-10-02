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

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 1))
    error_message = "The provided VPC CIDR block is not valid."
  }
}

variable "az_count" {
  description = "The number of availability zones to use"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Whether to use a single NAT gateway for the VPC"
  type        = bool
  default     = true
}

variable "flow_logs_retention_in_days" {
  description = "The number of days to retain VPC flow logs"
  type        = number
  default     = 30
}