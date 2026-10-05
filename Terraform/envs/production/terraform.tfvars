project     = "octabyte"
environment = "production"
owner       = "Likith Kumar"
aws_region  = "ap-south-1"

vpc_cidr           = "10.20.0.0/16"
single_nat_gateway = false
app_port           = 8000
app_image          = "octabyte/app:latest"
desired_count      = 2
min_capacity       = 2
max_capacity       = 6
log_retention_days = 30

db_instance_class        = "db.t3.micro"
db_multi_az              = true
db_backup_retention_days = 0
db_deletion_protection   = false
db_skip_final_snapshot   = false

enable_deletion_protection = false

alert_email = "likith04kumar@gmail.com"
