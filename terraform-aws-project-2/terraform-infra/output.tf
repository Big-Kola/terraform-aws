# VPC
output "vpc_id" {
  description = "VPC ID where resources are deployed"
  value       = aws_vpc.my_vpc.id
}

# Public ALB DNS
output "public_alb_dns" {
  description = "Public Application Load Balancer DNS"
  value       = aws_lb.public_alb.dns_name
}

# Internal ALB DNS
output "internal_alb_dns" {
  description = "Internal Application Load Balancer DNS"
  value       = aws_lb.int_alb.dns_name
}

# Bastion Instance ID
output "bastion_instance_id" {
  description = "Bastion EC2 Instance ID"
  value       = aws_instance.bastion.id
}

# Bastion Public IP
output "bastion_public_ip" {
  description = "Public IP of Bastion Host"
  value       = aws_instance.bastion.public_ip
}

# NAT Gateway Elastic IP
output "nat_gateway_public_ip" {
  description = "Elastic IP attached to NAT Gateway"
  value       = aws_eip.nat.public_ip
}

# Frontend Target Group ARN
output "frontend_target_group_arn" {
  description = "Frontend Target Group ARN"
  value       = aws_lb_target_group.frontend_tg.arn
}

# Backend Target Group ARN
output "backend_target_group_arn" {
  description = "Backend Target Group ARN"
  value       = aws_lb_target_group.backend_tg.arn
}

# RDS Endpoint
output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = aws_db_instance.postgres.address
}