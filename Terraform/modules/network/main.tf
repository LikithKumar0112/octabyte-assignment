#VPC with 3 tier subnets (public, private, and database) across multiple availability zones. The VPC will have a single NAT gateway for outbound internet access from the private subnets. VPC flow logs will be enabled with a retention period of 30 days.

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  public_subnet_cidrs = {
    for idx, az in local.azs :
    az => cidrsubnet(var.vpc_cidr, 4, idx)
  }

  private_app_subnet_cidrs = {
    for idx, az in local.azs :
    az => cidrsubnet(var.vpc_cidr, 4, idx + var.az_count)
  }

  private_db_subnet_cidrs = {
    for idx, az in local.azs :
    az => cidrsubnet(var.vpc_cidr, 4, idx + (2 * var.az_count))
  }

  name_prefix = "${var.project}-${var.environment}"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.name_prefix}-vpc"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${local.name_prefix}-igw"
    Project     = var.project
    Environment = var.environment
  }
}

#Subnets

resource "aws_subnet" "public" {
  for_each = local.public_subnet_cidrs

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name_prefix}-public-${each.key}"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_subnet" "private_app" {
  for_each = local.private_app_subnet_cidrs

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name        = "${local.name_prefix}-private-app-${each.key}"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_subnet" "private_db" {
  for_each = local.private_db_subnet_cidrs

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name        = "${local.name_prefix}-private-db-${each.key}"
    Project     = var.project
    Environment = var.environment
  }
}

#NAT Gateway

resource "aws_eip" "nat" {
  for_each = var.single_nat_gateway ? toset([shared]) : toset(local.azs)
  domain = "vpc"

  tags = {
    Name        = "${local.name_prefix}-nat-${count.index + 1}"
    Project     = var.project
    Environment = var.environment
  }
}

#route tablkes

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${local.name_prefix}-public-rt"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

#one private route table so each can point at its own NAT

resource "aws_route_table" "private" {
  for_each = toset(local.azs)
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${local.name_prefix}-private-rt"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_route" "private_nat" {
  for_each = aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.single_nat_gateway ? aws_nat_gateway.this["shared"].id : aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

#DB tier

resource "aws_route_table_association" "private_db" {
  for_each = aws_subnet.private_db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

#VPC Flow Logs

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${aws_vpc.this.id}/flow-logs"
  retention_in_days = var.flow_logs_retention_in_days
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${local.name_prefix}-vpc-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${local.name_prefix}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_flow_log" "this" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.this.id
}
