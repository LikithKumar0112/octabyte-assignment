project = "octabyte"
environment = "production"
owner = "Likith Kumar"
aws_region = "us-east-1"

vpc_cidr = "10.20.0.0/16"
single_nat_gateway = false
app_port = 8080
app_image = "octabyte/app:latest"
desired_count = 2
min_capacity = 2
max_capacity = 6
log_retention_days = 30

db_instance_class = "db.t3.micro"
db_multi_az = true
db_backup_retention_days = 14
db_deletion_protection = true
db_skip_final_snapshot = false

alert_email = "likith04kumar@gmail.com"
