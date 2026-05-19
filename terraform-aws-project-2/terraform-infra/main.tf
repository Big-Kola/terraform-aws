terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.44"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "random" {}

# DATA SOURCES

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}



# NETWORKING

resource "aws_vpc" "my_vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
}

# SUBNETS

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet2"
  }
}

resource "aws_subnet" "frontend_subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "frontend_subnet1"
  }
}

resource "aws_subnet" "frontend_subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "frontend_subnet2"
  }
}

resource "aws_subnet" "backend_subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "backend_subnet1"
  }
}

resource "aws_subnet" "backend_subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "backend_subnet2"
  }
}

resource "aws_subnet" "database_subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.7.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "database_subnet1"
  }
}

resource "aws_subnet" "database_subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.8.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "database_subnet2"
  }
}

# NAT

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  subnet_id     = aws_subnet.public_subnet1.id
  allocation_id = aws_eip.nat.id

  depends_on = [aws_internet_gateway.gw]
}

# ROUTES

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# ROUTE ASSOCIATIONS (unchanged structure)

resource "aws_route_table_association" "public_subnet1_assoc" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet2_assoc" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "frontend_subnet1_assoc" {
  subnet_id      = aws_subnet.frontend_subnet1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "frontend_subnet2_assoc" {
  subnet_id      = aws_subnet.frontend_subnet2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "backend_subnet1_assoc" {
  subnet_id      = aws_subnet.backend_subnet1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "backend_subnet2_assoc" {
  subnet_id      = aws_subnet.backend_subnet2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "database_subnet1_assoc" {
  subnet_id      = aws_subnet.database_subnet1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "database_subnet2_assoc" {
  subnet_id      = aws_subnet.database_subnet2.id
  route_table_id = aws_route_table.private_rt.id
}

# SECURITY GROUPS (unchanged)

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "frontend_sg" {
  name   = "frontend-sg"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend_sg" {
  name   = "backend-sg"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------
# FIXED S3 SECTION (IMPORTANT)
# --------------------------

resource "random_pet" "suffix" {
  length = 2
}

resource "aws_s3_bucket" "probucket" {
  bucket        = "kola-probucket-${random_pet.suffix.id}"
  force_destroy = true
}

resource "aws_lb" "public_alb" {
  name               = "public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public_subnet1.id,
    aws_subnet.public_subnet2.id
  ]
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Allow SSH access"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database_sg" {
  name        = "database-sg"
  description = "Allow PostgreSQL from backend only"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "postgres" {
  name       = "postgres-subnet-group"
  subnet_ids = [
    aws_subnet.database_subnet1.id,
    aws_subnet.database_subnet2.id
  ]

  tags = {
    Name = "postgres-subnet-group"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "goal-tracker-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "goalsdb"
  username               = "postgres"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false

  tags = {
    Name = "goal-tracker-db"
  }
}

# TARGET GROUPS

resource "aws_lb_target_group" "frontend_tg" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# LOAD BALANCERS

resource "aws_lb" "int_alb" {
  name               = "int-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_sg.id]

  subnets = [
    aws_subnet.backend_subnet1.id,
    aws_subnet.backend_subnet2.id
  ]
}

# LISTENERS

resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener" "backend_listener" {
  load_balancer_arn = aws_lb.int_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# LAUNCH TEMPLATES

resource "aws_launch_template" "frontend_lt" {
  name_prefix   = "frontend-template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.frontend_sg.id
  ]

  key_name = "ansible-jenkins"

  user_data = base64encode(templatefile("${path.module}/userdata_frontend.sh", {
    alb_dns = aws_lb.int_alb.dns_name
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "frontend-instance"
    }
  }
}

resource "aws_launch_template" "backend_lt" {
  name_prefix   = "backend-template"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.backend_sg.id
  ]

  key_name = "ansible-jenkins"

  user_data = base64encode(templatefile("${path.module}/userdata_backend.sh", {
    db_host     = aws_db_instance.postgres.address
    db_password = var.db_password
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "backend-instance"
    }
  }
}

# AUTO SCALING GROUPS

resource "aws_autoscaling_group" "frontend_asg" {
  name                      = "frontend-asg"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true

  target_group_arns = [aws_lb_target_group.frontend_tg.arn]

  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }

  vpc_zone_identifier = [
    aws_subnet.frontend_subnet1.id,
    aws_subnet.frontend_subnet2.id
  ]
}

resource "aws_autoscaling_group" "backend_asg" {
  name                      = "backend-asg"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true

  target_group_arns = [aws_lb_target_group.backend_tg.arn]

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }

  vpc_zone_identifier = [
    aws_subnet.backend_subnet1.id,
    aws_subnet.backend_subnet2.id
  ]
}

# BASTION HOST

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                    = "ansible-jenkins"

  tags = {
    Name = "bastion-host"
  }
}