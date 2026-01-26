output "lb_dns" {
  description = "DNS name of the backend load balancer"
  value       = aws_lb.backend.dns_name
}

output "security_group_id" {
  description = "Backend security group ID"
  value       = aws_security_group.backend.id
}

output "autoscaling_group_name" {
  description = "Name of the backend Auto Scaling group"
  value       = aws_autoscaling_group.backend.name
}

output "lb_arn" {
  description = "ARN of the backend load balancer"
  value       = aws_lb.backend.arn
}

output "lb_name" {
  description = "Name of the backend load balancer"
  value       = aws_lb.backend.name
}

output "lb_arn_suffix" {
  description = "ARN suffix of the backend load balancer"
  value       = aws_lb.backend.arn_suffix
}
