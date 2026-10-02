locals {
  name_prefix = "${var.project}-${var.environment}"
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "acess_logs" {
  bucket        = "${local.name_prefix}-alb-logs-${var.account_id}"
  force_destroy = true
  tags = {
    Name        = "${local.name_prefix}-alb-logs"
    Project     = var.project
    Environment = var.environment
  }
}
resource "aws_s3_bucket_public_access_block" "acess_logs" {
  bucket = aws_s3_bucket.acess_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "acess_logs" {
  bucket = aws_s3_bucket.acess_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "acess_logs" {
  bucket = aws_s3_bucket.acess_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowELBWrite"
      Effect    = "Allow"
      Principal = { AWS = data.aws_elb_service_account.main.arn }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.acess_logs.arn}/alb/AWSLogs/${var.account_id}/*"
    }]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "acess_logs" {
  bucket = aws_s3_bucket.acess_logs.id

  rule {
    id     = "expire_old_logs"
    status = "Enabled"

    expiration {
      days = var.log_retention_in_days
    }
  }
}

resource "aws_alb" "this" {
  name                       = "${local.name_prefix}-alb"
  load_balancer_type         = "application"
  internal                   = false
  subnets                    = var.public_subnet_ids
  security_groups            = [var.alb_sg_id]
  drop_invalid_header_fields = true
  enable_deletion_protection = var.enable_delete_protection

  access_logs {
    bucket  = aws_s3_bucket.acess_logs.bucket
    prefix  = "alb"
    enabled = true
  }
  depends_on = [aws_s3_bucket.acess_logs]
  tags = {
    Name        = "${local.name_prefix}-alb"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_alb_target_group" "this" {
  name        = "${local.name_prefix}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "${local.name_prefix}-tg"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.this.arn
  }

  tags = {
    Name        = "${local.name_prefix}-listener"
    Project     = var.project
    Environment = var.environment
  }
}