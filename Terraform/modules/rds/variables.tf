variable "project" {
  description = "The project name"
  type        = string
  default     = "octabyte-assignment"
}

variable "environment" {
  description = "The environment name"
  type        = string
  default     = "dev"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the RDS instance"
  type        = list(string)
}

variable "engine_version" {
  description = "The version of the database engine"
  type        = string
  default     = "16.15"
}

variable "instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "The maximum allocated storage in gigabytes"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "mydatabase"
}

variable "db_username" {
  description = "The username for the database"
  type        = string
  default     = "appadmin"
}

variable "db_sg_id" {
  description = "The security group ID for the RDS instance"
  type        = string
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

variable "retenction_days" {
  description = "The number of days to retain backups for the RDS instance"
  type        = number
  default     = 7
}

variable "backup_retention_days" {
  description = "The number of days to retain backups for the RDS instance"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Specifies if the RDS instance has deletion protection enabled"
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "The name of the final DB snapshot when the DB instance is deleted"
  type        = string
  default     = "final-snapshot"
}

variable "skip_final_snapshot" {
  description = "Specifies whether to skip the creation of a final DB snapshot before the DB instance is deleted"
  type        = bool
  default     = false
}


