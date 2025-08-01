output "security_group_backend_id" {
  description = "The ID of the backend security group."
  value       = aws_security_group.backend.id
}

output "backend_private_ip" {
  description = "The private IP address of the backend instance."
  value       = aws_instance.backend.private_ip
}
