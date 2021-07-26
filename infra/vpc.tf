resource "aws_vpc" "public" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "public-vpc"
  }
}
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.public.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = var.public_az
  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.public.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.public_bz
  tags = {
    Name = "public-subnet-b"
  }
}

resource "aws_vpc_endpoint" "dynamo" {
  vpc_id       = aws_vpc.public.id
  service_name = "com.amazonaws.${var.region}.dynamodb"
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.public.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.public.id
}

resource "aws_route" "public_route_a" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}


resource "aws_route" "public_route_b" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_route_table_association_subnet_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_association_subnet_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "elastic_ip" {
  vpc = true

  tags = {
    Name = "elastic-ip"
  }
}

resource "aws_vpc_endpoint_route_table_association" "public_route_table_dynamo" {
  route_table_id  = aws_route_table.public_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.dynamo.id
}

resource "aws_security_group" "security_group" {
  name        = "VPC Security group"
  description = "Allowed HTTP Trafic"
  vpc_id      = aws_vpc.public.id
}

resource "aws_security_group" "ecs_security_group" {
  name        = "ECS Security group"
  description = "ECS Trafic"
  vpc_id      = aws_vpc.public.id
}

resource "aws_security_group" "lambda_security_group" {
  name        = "Lambda Security group"
  description = "Allowed outbound traffic"
  vpc_id      = aws_vpc.public.id
}

resource "aws_security_group_rule" "security_group_inbound_rule" {
  type              = "ingress"
  description       = "Http inbound VPC"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "security_group_http_outbound_rule" {
  description       = "Http outbound VPC"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "ecs_outbound_security_group" {
  description       = "Outbound VPC"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_security_group.id
}

resource "aws_security_group_rule" "ecs_inbound_security_group" {
  description              = "Inbound ecs"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.ecs_security_group.id
  source_security_group_id = aws_security_group.security_group.id
}

resource "aws_security_group_rule" "lambda_inbound_security_group" {
  description       = "Inbound lambda"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_security_group.id
}

resource "aws_security_group_rule" "lambda_outbound_security_group" {
  description       = "Outbound lambda"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_security_group.id
}
