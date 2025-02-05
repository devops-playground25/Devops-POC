provider "aws" {
  region = "eu-west-2"
}

resource "tls_private_key" "self_signed_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "devops_key" {
  key_name   = "devops-key"
  public_key = tls_private_key.self_signed_key.public_key_openssh
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
  description = "Allow inbound SSH and HTTP"
  vpc_id      = aws_vpc.devops_playground.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "web" {
  ami                  = "ami-091f18e98bc129c4e"
  instance_type        = "t2.micro"
  key_name             = aws_key_pair.devops_key.key_name
  subnet_id            = aws_subnet.devops_subnet_1.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y nginx
              echo "Hello World from Terraform!" | sudo tee /var/www/html/index.html
              sudo systemctl enable nginx
              sudo systemctl start nginx
              EOF

  tags = {
    Name = "Terraform-EC2-Instance"
  }
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}