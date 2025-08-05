output "lb_dns" {
  description = "DNS name of the backend load balancer"
  value       = aws_lb.backend.dns_name
}

output "security_group_id" {
  description = "Backend security group ID"
  value       = aws_security_group.backend.id
}
