# I have to define my VPC and subnets here first

# what do i need to setup a VPC and subnet?

# my first step here is to check with AWS to know which AZs exist in my region
data "aws_availability_zones" "check_availability" {
  state = "available"
}

# next, I have to create a vpc using the necessary information
resource "aws_vpc" "create_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

# i need to use a consistent naming convention here as per the task instruction
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# since we have can have either a public or private subnet, I have to seperately treat both
# for the cidr blcok, I used the cidr subnet function: cidrsubnet(prefix, newbits, netnum)
resource "aws_subnet" "public" {
  count = var.az_count
  vpc_id = aws_vpc.create_vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.check_availability.names[count.index]
  map_public_ip_on_launch = true


  tags = {
    Name = "${var.name_prefix}-public-${count.index}"
  }
}

# since my cidr is 10.0.0.0/16, in order to give the private subnet a different cidr, I added +100 to ensure that its cidr notation is always different from the public subnet
# 10.0.100.0/16
resource "aws_subnet" "private" {
  count = var.az_count
  vpc_id = aws_vpc.create_vpc.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index + 100)
  availability_zone = data.aws_availability_zones.check_availability.names[count.index]

  tags = {
    Name = "${var.name_prefix}-private-${count.index}"
  }
}


# Next, here is for the routes and gateways

resource "aws_internet_gateway" "create_internet_gateway" {
  vpc_id = aws_vpc.create_vpc.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

resource "aws_eip" "nat_gateway" {
  count = var.nat_gateway_enable ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "create_nat_gateway" {
  count = var.nat_gateway_enable ? 1 : 0
  allocation_id = aws_eip.nat_gateway[0].id
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${var.name_prefix}-nat-gateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.create_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.create_internet_gateway.id
  }

  tags = {
    Name = "${var.name_prefix}-pub-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = var.az_count
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.create_vpc.id

  tags = {
    Name = "${var.name_prefix}-priv-rt"
  }
}

resource "aws_route" "private_nat" {
  count = var.nat_gateway_enable ? 1 : 0
  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.create_nat_gateway[0].id
}

resource "aws_route_table_association" "private" {
  count = var.az_count
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# the security group
# so, AWS automatically creates one default SG per VPC which permits all traffic, both all outbound traffic too
# so, the aws_default_sg is to tell terraform to adopt and manage the SG already auto-created rather than creating a new one
resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.create_vpc.id
}
