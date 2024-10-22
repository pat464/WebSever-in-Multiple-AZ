#VPC ID output
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.TEST.id #uses attribute reference
  sensitive   = false
}
#Public subnet IDs output
output "public_subnet_ids" {
  description = "Public Subnet ID"
  value       = [aws_subnet.PublicSubnet1.id, aws_subnet.PublicSubnet2.id]
  sensitive   = false
}
#DNS name
output "lb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.test.dns_name
  sensitive   = false
}



