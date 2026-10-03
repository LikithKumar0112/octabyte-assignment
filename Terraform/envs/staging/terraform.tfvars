project     = "my-project"
environment = "staging"
owner       = "Likith Kumar"
aws_region  = "ap-south-1"

vpc_cidr           = "10.10.0.0/16"
single_nat_gateway = true

app_port  = 8000
app_image = "897545289989.dkr.ecr.ap-south-1.amazonaws.com/octabyte-assignment-ecr-repo:bootstrap"

desired_count      = 2
min_capacity       = 2
max_capacity       = 4
log_retention_days = 7
db_instance_class  = "db.t4g.micro"
db_backup_retention_days = 0
alert_email        = "likith04kumar@gmail.com"