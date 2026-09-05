# Project 3: AWS Networking Lab as Infrastructure as Code (Terraform)
# Author: Adil Majeed
#
# This file recreates the same VPC + public networking + EC2 setup that was
# first built manually in the AWS Console (see project-1 and project-2 in
# this repo), this time fully defined as code using Terraform.
 
provider "aws" {
  region = "us-east-1"
}
 
# ---------------------------------------------------------------------------
# VPC - the private network everything else lives inside
# ---------------------------------------------------------------------------
resource "aws_vpc" "adil_tf_vpc" {
  cidr_block = "10.20.0.0/16"
 
  tags = {
    Name = "adil-terraform-vpc"
  }
}
 
# ---------------------------------------------------------------------------
# Public Subnet - lives inside the VPC
# ---------------------------------------------------------------------------
resource "aws_subnet" "adil_tf_subnet" {
  vpc_id     = aws_vpc.adil_tf_vpc.id
  cidr_block = "10.20.1.0/24"
 
  tags = {
    Name = "adil-terraform-subnet"
  }
}
 
# ---------------------------------------------------------------------------
# Internet Gateway - attaches to the VPC, gives it a path to the internet
# ---------------------------------------------------------------------------
resource "aws_internet_gateway" "adil_tf_igw" {
  vpc_id = aws_vpc.adil_tf_vpc.id
 
  tags = {
    Name = "adil-terraform-igw"
  }
}
 
# ---------------------------------------------------------------------------
# Route Table - the "map" that sends internet-bound traffic through the IGW,
# then associated with the subnet so the subnet actually uses this route
# ---------------------------------------------------------------------------
resource "aws_route_table" "adil_tf_rt" {
  vpc_id = aws_vpc.adil_tf_vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.adil_tf_igw.id
  }
 
  tags = {
    Name = "adil-terraform-rt"
  }
}
 
resource "aws_route_table_association" "adil_tf_rta" {
  subnet_id      = aws_subnet.adil_tf_subnet.id
  route_table_id = aws_route_table.adil_tf_rt.id
}
 
# ---------------------------------------------------------------------------
# Security Group - firewall rules for the EC2 instance
# SSH is restricted to a single IP (/32) - replace with your own current
# public IP before applying. All outbound traffic is allowed.
# ---------------------------------------------------------------------------
resource "aws_security_group" "adil_tf_sg" {
  name   = "adil-terraform-sg"
  vpc_id = aws_vpc.adil_tf_vpc.id
 
  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.10/32"] # <-- replace with your own public IP
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "adil-terraform-sg"
  }
}
 
# ---------------------------------------------------------------------------
# Data source - looks up the latest Amazon Linux 2023 AMI automatically
# instead of hardcoding an AMI ID that would go stale over time
# ---------------------------------------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
 
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
 
# ---------------------------------------------------------------------------
# EC2 Instance - launched inside the public subnet, using the security
# group above and an existing SSH key pair
# ---------------------------------------------------------------------------
resource "aws_instance" "adil_tf_ec2" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.adil_tf_subnet.id
  vpc_security_group_ids      = [aws_security_group.adil_tf_sg.id]
  key_name                    = "adil-key-for-ec2" # <-- replace with your own key pair name
  associate_public_ip_address = true
 
  tags = {
    Name = "adil-terraform-ec2"
  }
}
 
# ---------------------------------------------------------------------------
# Outputs - print useful info after `terraform apply` instead of having to
# look it up manually in the AWS Console
# ---------------------------------------------------------------------------
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.adil_tf_ec2.public_ip
}
 
output "vpc_id" {
  description = "ID of the VPC created by this project"
  value       = aws_vpc.adil_tf_vpc.id
}
