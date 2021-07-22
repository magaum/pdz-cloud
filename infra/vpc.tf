resource "aws_vpc" "private" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "private"
  }
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.private.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-a"
  }
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.private.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1f"
  tags = {
    Name = "subnet-b"
  }
}

# resource "aws_route_table" "private" {
#   vpc_id = "${aws_vpc.private.id}"

#   tags {
#     Name        = "private-route-table"
#     Environment = var.Environment
#   }
# }

resource "aws_security_group" "contagem" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.private.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.private.id

  tags = {
    Name = "vpc-private-igw"
  }
}
