resource "aws_vpc" "private" {
  cidr_block       = "172.16.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "private"
  }
}

resource "aws_vpc" "public" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.private.id
  cidr_block        = "172.16.1.0/24"

  tags = {
    Name = "subnet-private-a"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id            = aws_vpc.public.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet-public-b"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.public.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1f"
  tags = {
    Name = "subnet-public-a"
  }
}

resource "aws_security_group" "private_contagem" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.private.id

  ingress {
    description = "Http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_security_group" "public_contagem" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.public.id

  ingress {
    description = "Http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.public.id

  tags = {
    Name = "vpc-public-igw"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.private.id

  tags = {
    Name        = "private-route-table"
    Environment = var.Environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.public.id

  tags = {
    Name        = "public-route-table"
    Environment = var.Environment
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# resource "aws_eip" "nat_eip" {
#   vpc        = true
#   depends_on = [aws_internet_gateway.igw]
# }

# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.nat_eip.id
#   subnet_id     = aws_subnet.public_subnet_a.id
#   depends_on    = [aws_internet_gateway.igw]

#   tags = {
#     Name        = "nat-gateway"
#     Environment = var.Environment
#   }
# }


# resource "aws_route" "private_nat_gateway" {
#   route_table_id         = aws_route_table.private.id
#   destination_cidr_block = "0.0.0.0/0"
#   nat_gateway_id         = aws_nat_gateway.nat.id
# }

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private.id
}


resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public.id
}
