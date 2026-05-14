output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.my_server.id
}

output "public_ip" {
  description = "Public IP address of the server"
  value       = aws_instance.my_server.public_ip
}

output "vpc_id" {
  description = "VPC ID where resources are deployed"
  value       = aws_vpc.main.id
}

output "load_balancer_url" {
  description = "URL to access the load balancer"
  value       = "http://${aws_lb.main.dns_name}"
}
