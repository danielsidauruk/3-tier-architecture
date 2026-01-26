output "security_group_id" {
  description = "Frontend security group ID."
  value       = aws_security_group.frontend.id
}

output "lb_dns" {
  description = "Application URL."
  value       = aws_lb.frontend.dns_name
}

output "autoscaling_group_name" {
  description = "Name of the frontend Auto Scaling group"
  value       = aws_autoscaling_group.frontend.name
}

output "lb_arn" {
  description = "ARN of the frontend load balancer"
  value       = aws_lb.frontend.arn
}

output "lb_name" {
  description = "Name of the frontend load balancer"
  value       = aws_lb.frontend.name
}

output "lb_arn_suffix" {
  description = "ARN suffix of the frontend load balancer"
  value       = aws_lb.frontend.arn_suffix
}
