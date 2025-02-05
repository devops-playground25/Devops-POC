provider "aws" {
  region = "eu-west-2"
}

resource "tls_private_key" "devops_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "devops_key" {
  key_name   = "devops-key"
  public_key = tls_private_key.devops_key.public_key_openssh
}

resource "aws_acm_certificate" "alb_cert" {
  domain_name       = "yourdomain.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc" "devops_playground" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "devops-playground"
  }
}

resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.devops_playground.id

  tags = {
    Name = "devops-igw"
  }
}

resource "aws_route_table" "devops_route_table" {
  vpc_id = aws_vpc.devops_playground.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_igw.id
  }

  tags = {
    Name = "devops-route-table"
  }
}

resource "aws_route_table_association" "subnet_1_assoc" {
  subnet_id      = aws_subnet.devops_subnet_1.id
  route_table_id = aws_route_table.devops_route_table.id
}

resource "aws_route_table_association" "subnet_2_assoc" {
  subnet_id      = aws_subnet.devops_subnet_2.id
  route_table_id = aws_route_table.devops_route_table.id
}

resource "aws_subnet" "devops_subnet_1" {
  vpc_id                  = aws_vpc.devops_playground.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "devops-subnet-1"
  }
}

resource "aws_subnet" "devops_subnet_2" {
  vpc_id                  = aws_vpc.devops_playground.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "devops-subnet-2"
  }
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow inbound SSH, HTTP, and HTTPS"
  vpc_id      = aws_vpc.devops_playground.id

  ingress {
    from_port   = 22
    to_port     = 22
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
}

resource "aws_lb" "web_lb" {
  name               = "web-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.devops_subnet_1.id, aws_subnet.devops_subnet_2.id]
  enable_deletion_protection = false
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.alb_cert.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "HTTPS works!"
      status_code  = "200"
    }
  }
}

resource "aws_instance" "web" {
  ami                  = "ami-091f18e98bc129c4e"
  instance_type        = "t2.micro"
  key_name             = aws_key_pair.devops_key.key_name
  subnet_id            = aws_subnet.devops_subnet_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "Terraform-EC2-Instance"
  }
}

output "private_key" {
  value     = tls_private_key.devops_key.private_key_pem
  sensitive = true
}
