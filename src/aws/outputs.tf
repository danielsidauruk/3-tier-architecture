output "access_to_web" {
  description = "Frontend ELB's url."
  value       = module.frontend.lb_dns
}