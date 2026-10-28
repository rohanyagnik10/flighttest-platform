data "aws_availability_zones" "available" {
    state = "available"
}

resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = var.name
    }
}

resource "aws_subnet" "public" {
    for_each = {
        a = {
            az = data.aws_availability_zones.available.names[0]
            cidr = cidrsubnet(var.vpc_cidr, 4, 0)

        }

        b = {
            az = data.aws_availability_zones.available.names[1]
            cidr = cidrsubnet(var.vpc_cidr,4,1)
        }
    }
    vpc_id = aws_vpc.main.id
    availability_zone = each.value.az
    cidr_block = each.value.cidr
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.name}-public-${each.key}"
        "kubernetes.io/role/elb" = "1"
    }
}

resource "aws_subnet" "private" {
     for_each = {
    a = {
      az   = data.aws_availability_zones.available.names[0]
      cidr = cidrsubnet(var.vpc_cidr, 4, 8)
    }

    b = {
      az   = data.aws_availability_zones.available.names[1]
      cidr = cidrsubnet(var.vpc_cidr, 4, 9)
    }
  }

  vpc_id            = aws_vpc.main.id
  availability_zone = each.value.az
  cidr_block        = each.value.cidr

  tags = {
    Name = "${var.name}-private-${each.key}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.name}-public-routes"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-private-routes"
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.eu-west-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name = "${var.name}-s3-endpoint"
  }
}

resource "aws_security_group" "web" {
  name   = "${var.name}-web"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-web"
  }
}

resource "aws_security_group" "db" {
  name   = "${var.name}-db"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-db"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_web" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Postgres from web only"
}
resource "aws_vpc_security_group_egress_rule" "web_to_db" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Postgres to db only"
}

resource "aws_vpc_security_group_egress_rule" "web_https_out" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS out for S3, updates and APIs"
}

resource "aws_eip" "nat" {
    domain = "vpc"

    tags = {
        Name = "${var.name}-nat-ip"
    }
}

resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public["a"].id

    tags = {
        Name = "${var.name}-nat"
    }

    depends_on = [aws_internet_gateway.main]
}

resource "aws_route" "private_nat" {
    route_table_id = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
}
