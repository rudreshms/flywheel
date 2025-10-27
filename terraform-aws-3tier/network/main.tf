resource "aws_vpc" "test_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "tf-3tier-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.test_vpc.id
  tags   = { Name = "tf-3tier-igw" }
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each                = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = var.azs[tonumber(each.key)]

  tags = {
    Name = "public-${each.value}"
  }
}

# App Private Subnets
resource "aws_subnet" "app" {
  for_each = { for idx, cidr in var.private_app_subnet_cidrs : idx => cidr }

  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  availability_zone       = var.azs[tonumber(each.key)]

  tags = {
    Name = "app-${each.value}"
  }
}

# DB Private Subnets
resource "aws_subnet" "db" {
  for_each = { for idx, cidr in var.private_db_subnet_cidrs : idx => cidr }

  vpc_id                  = aws_vpc.test_vpc.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  availability_zone       = var.azs[tonumber(each.key)]

  tags = {
    Name = "db-${each.value}"
  }
}

# Route Table for Public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.test_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (Its an optional)
resource "aws_eip" "nat" {
  count = var.enable_nat ? length(aws_subnet.public) : 0
}

resource "aws_nat_gateway" "nat" {
  count         = var.enable_nat ? length(aws_subnet.public) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(values(aws_subnet.public)[*].id, count.index)
  tags          = { Name = "nat-${count.index}" }
}

# Private route tables for app and db
resource "aws_route_table" "private" {
  for_each = {
    app = "app"
    db  = "db"
  }
  vpc_id = aws_vpc.test_vpc.id
  tags   = { Name = "private-rt-${each.key}" }
}

# Attach route to NAT if enabled, else no default route
resource "aws_route" "private_default_route" {
  # Only create if NAT is enabled
  for_each               = var.enable_nat ? aws_route_table.private : {}
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat[*].id, 0)
  depends_on             = [aws_nat_gateway.nat]
}

resource "aws_route_table_association" "app_assoc" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private["app"].id
}

resource "aws_route_table_association" "db_assoc" {
  for_each       = aws_subnet.db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private["db"].id
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "alb-sg"
  vpc_id      = aws_vpc.test_vpc.id
  description = "ALB security group"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "alb-sg" }
}

resource "aws_security_group" "app" {
  name        = "app-sg"
  vpc_id      = aws_vpc.test_vpc.id
  description = "App instances SG"
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # restrict in prod
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "app-sg" }
}

resource "aws_security_group" "db" {
  name        = "db-sg"
  vpc_id      = aws_vpc.test_vpc.id
  description = "DB SG"
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "db-sg" }
}

output "vpc_id" { value = aws_vpc.test_vpc.id }
output "public_subnet_ids" { value = values(aws_subnet.public)[*].id }
output "app_subnet_ids" { value = values(aws_subnet.app)[*].id }
output "db_subnet_ids" { value = values(aws_subnet.db)[*].id }
output "alb_sg_id" { value = aws_security_group.alb.id }
output "app_sg_id" { value = aws_security_group.app.id }
output "db_sg_id" { value = aws_security_group.db.id }