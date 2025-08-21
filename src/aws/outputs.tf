output "access_to_web" {
  description = "url of public frontend application"
  value       = module.frontend.lb_dns
}

output "backend_asg_name" {
  description = "Name of the backend Auto Scaling Group"
  value       = module.backend.asg_name
}

output "frontend_asg_name" {
  description = "Name of the frontend Auto Scaling Group"
  value       = module.frontend.asg_name
}
