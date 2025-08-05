output "security_group_id" {
  description = "The ID of the frontend security group."
  value       = aws_security_group.frontend.id
}

output "lb_dns" {
  description = "url of application"
  value       = aws_lb.frontend.dns_name
}
