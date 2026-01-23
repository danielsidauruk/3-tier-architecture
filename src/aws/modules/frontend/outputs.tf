output "security_group_id" {
  description = "Frontend security group ID."
  value       = aws_security_group.frontend.id
}

output "lb_dns" {
  description = "Application URL."
  value       = aws_lb.frontend.dns_name
}