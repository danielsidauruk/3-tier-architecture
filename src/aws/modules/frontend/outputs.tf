output "security_group_id" {
  description = "The ID of the frontend security group."
  value       = aws_security_group.frontend.id
}

output "lb_dns" {
  description = "url of application"
  value       = aws_lb.frontend.dns_name
}

output "asg_name" {
  description = "Name of the frontend Auto Scaling Group"
  value       = aws_autoscaling_group.frontend.name
}
