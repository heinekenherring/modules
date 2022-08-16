// Availability Zones
data "aws_availability_zones" "available" {
  state = "available"
}

// VPC
resource "aws_vpc" "eks" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "${var.cluster_name}-cluster/VPC"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Network ACL Rules
resource "aws_network_acl_rule" "deny_ssh" {
  network_acl_id = aws_vpc.eks.default_network_acl_id
  rule_number    = 20
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "deny_rdp" {
  network_acl_id = aws_vpc.eks.default_network_acl_id
  rule_number    = 21
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}

// Public Subnets
resource "aws_subnet" "public" {
  count = length(var.aws_subnet_public_cidr)

  vpc_id                  = aws_vpc.eks.id
  cidr_block              = var.aws_subnet_public_cidr[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = tomap({
    "Name"                                      = "${var.cluster_name}-cluster/SubnetPublic/${data.aws_availability_zones.available.names[count.index]}",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
    "kubernetes.io/role/elb"                    = "1"
  })

  lifecycle {
    create_before_destroy = true
  }
}

// Private Subnets
resource "aws_subnet" "private" {
  count = length(var.aws_subnet_private_cidr)

  vpc_id            = aws_vpc.eks.id
  cidr_block        = var.aws_subnet_private_cidr[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = tomap({
    "Name"                                      = "${var.cluster_name}-cluster/SubnetPrivate/${data.aws_availability_zones.available.names[count.index]}",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
    "kubernetes.io/role/elb"                    = "1"
  })

  lifecycle {
    create_before_destroy = true
  }
}

// Internet Gateway
resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id

  tags = {
    Name = "${var.cluster_name}-cluster/InternetGateway"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Public Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }

  tags = {
    Name = "${var.cluster_name}-cluster/PublicRouteTable"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.aws_subnet_public_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id

  lifecycle {
    create_before_destroy = true
  }
}

// NAT IP
resource "aws_eip" "nat_ip" {
  vpc        = true
  depends_on = [aws_internet_gateway.eks]

  tags = {
    Name = "${var.cluster_name}-cluster/NATIP"
  }

  lifecycle {
    create_before_destroy = true
  }
}

// NAT gateway
resource "aws_nat_gateway" "eks" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.cluster_name}-cluster/NATGateway"
  }

  depends_on = [aws_internet_gateway.eks]

  lifecycle {
    create_before_destroy = true
  }
}

// Private Route Tables
resource "aws_route_table" "private" {
  count = length(var.aws_subnet_private_cidr)

  vpc_id = aws_vpc.eks.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks.id
  }

  tags = {
    Name = "${var.cluster_name}-cluster/PrivateRouteTable/${data.aws_availability_zones.available.names[count.index]}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.aws_subnet_private_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id

  lifecycle {
    create_before_destroy = true
  }
}