terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.44.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# VPC with 8 subnets across 2 AZs (public, frontend, backend, database)

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet1" {
vpc_id = aws_vpc.my_vpc.id
cidr_block = var.cidr_block
availability_zone = "us-east-2a"
tags = {
Name = "public_subnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
vpc_id = aws_vpc.my_vpc.id
cidr_block = var.cidr_block
availability_zone = "us-east-2b"
tags = {
Name = "public_subnet2"
  }
}

resource "aws_subnet" "frontend_subnet1" {
vpc_id = aws_vpc.my_vpc.id
cidr_block = var.cidr_block
availability_zone = "us-east-2a"
tags = {
Name = "frontend_subnet1"
  }
}

resource "aws_subnet" "frontend_subnet2" {
vpc_id = aws_vpc.my_vpc.id
cidr_block = var.cidr_block
availability_zone = "us-east-2b"
tags = {
Name = "frontend_subnet2"
  }
}

resource "aws_subnet" "backend_subnet1" {
vpc_id = aws_vpc.my_vpc.id
cidr_block = var.cidr_block
availability_zone = "us-east-2a"
tags = {
Name = "backend_subnet1"
  }
}

resource "aws_subnet" "backend_subnet2" {
vpc_id = aws_vpc.my_vpc.id
cidr_block = var.cidr_block
availability_zone = "us-east-2b"
tags = {
Name = "backend_subnet2"
  }
}

resource "aws_subnet" "database_subnet1" {
vpc_id = aws_vpc.my_vpc.id
cidr_block = var.cidr_block
availability_zone = "us-east-2a"
tags = {
Name = "database_subnet1"
  }
}

resource "aws_subnet" "database_subnet2" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2b"
  tags = {
  Name = "database_subnet2"
  }
}

# Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app_lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.public : aws_subnetpublic_subnet1, aws_subnetpublic_subnet2]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.id
    prefix  = "app-lb"
    enabled = true
  }
}


# Internal ALB for backend communication
resource "aws_lb" "app_lb" {
  name               = "app_lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [for subnet in aws_subnet.backend : aws_subnet.backend_subnet1, aws_subnet.backend_subnet2]
}

#- Auto Scaling Groups (Frontend: 2-4) 
resource "aws_autoscaling_group" "frontend_asg" {
  name                      = "frontend_asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  placement_group           = aws_placement_group.test.id
  launch_configuration      = aws_launch_configuration.foobar.frontend_asg
  vpc_zone_identifier       = [aws_subnet.frontend_subnet1.id, aws_subnet.frontend_subnet2.id]
}

# Backend: 2-6 instances
resource "aws_autoscaling_group" "backend_asg" {
  name                      = "backend_asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  placement_group           = aws_placement_group.test.id
  launch_configuration      = aws_launch_configuration.foobar.backend_asg
  vpc_zone_identifier       = [aws_subnet.backend_subnet1.id, aws_subnet.backend_subnet2.id]
}

# NAT Gateway for private subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gw.id
  subnet_id     = aws_subnet.nat_gw.id

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.nat_gw]
} 

# Bastion host for SSH access
resource "aws_instance" "bastion" {
ami = "ami-xxxxxxxx"
instance_type = "t2.micro"
key_name = "default-key"
}