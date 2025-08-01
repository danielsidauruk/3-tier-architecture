output "security_group_frontend_id" {
  description = "The ID of the frontend security group."
  value       = aws_security_group.frontend.id
}

output "public_ip" {
  description = "The public IP address of the frontend instance."
  value       = aws_instance.frontend.public_ip
}
