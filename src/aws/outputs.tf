output "access_to_web" {
  description = "The public IP address of the frontend instance."
  value       = module.frontend.public_ip
}
