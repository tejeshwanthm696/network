terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "eu-west-1"
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "CA1"
  }
}

# Create a public subnet
resource "aws_subnet" "example" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Main"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "Main-GW"
  }
}

# Create a route table for public access
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "Public-RT"
  }
}

# Add a route to allow internet access via Internet Gateway
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

# Associate the route table with the public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.example.id
  route_table_id = aws_route_table.public.id
}

# Create a security group
resource "aws_security_group" "test" {
  vpc_id = aws_vpc.example.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow-All"
  }
}

# Create a security group to allow SSH access
resource "aws_security_group" "ssh_access" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
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

# Security group rule for internal traffic
resource "aws_security_group_rule" "example" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [aws_vpc.example.cidr_block]
  security_group_id = aws_security_group.test.id
}

resource "aws_security_group" "allow_outgoing" {
  name        = "allow_outgoing"
  description = "Allow all outgoing traffic"
  vpc_id      = aws_vpc.example.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allows all protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allows traffic to any destination
  }
}

# Create an EC2 instance
resource "aws_instance" "example" {
  ami                    = "ami-03fd334507439f4d1"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.example.id
  associate_public_ip_address = true
  security_groups        = [aws_security_group.test.id]
  key_name               = "networksCA"

  tags = {
    Name = "Instance"
  }

  depends_on = [aws_internet_gateway.gw]
}

# Output the EC2 instance's public IP
output "instance_public_ip" {
  value = aws_instance.example.public_ip
}
