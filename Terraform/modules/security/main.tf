locals {
  project     = var.project
  environment = var.environment
  name_prefix = "${local.project}-${local.environment}"
}

#ALB SG

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Internet facing ALB security group"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "${local.name_prefix}-alb-sg"
    Environment = local.environment
    Project     = local.project
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_internet" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to the app on its container port"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

#ECS task security group

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "ECS task security group"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "${local.name_prefix}-app-sg"
    Environment = local.environment
    Project     = local.project
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Allow traffic from the ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_internet_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS out, via NAT, for ECR / Secrets Manager / CloudWatch"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "Postgres to the db tier"
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

#Db SG

resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "RDS security group"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "${local.name_prefix}-db-sg"
    Environment = local.environment
    Project     = local.project
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "Allow traffic from the app"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
