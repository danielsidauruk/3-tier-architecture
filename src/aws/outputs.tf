output "access_to_web" {
  description = "url of public frontend application"
  value       = module.frontend.lb_dns
}
