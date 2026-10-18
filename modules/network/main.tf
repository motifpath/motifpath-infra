resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = var.name }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = var.name }
}

# The VM's subnet. There is no NAT gateway: the VM reaches the internet
# through its own public address.
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, 0)
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = { Name = "${var.name}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.name}-public" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Subnets with no route out, for the database. RDS needs a subnet group that
# spans at least two availability zones even for a single-AZ instance.
resource "aws_subnet" "private" {
  for_each = { for index, zone in var.availability_zones : zone => index }

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 10 + each.value)
  availability_zone = each.key

  tags = { Name = "${var.name}-private-${each.key}" }
}
