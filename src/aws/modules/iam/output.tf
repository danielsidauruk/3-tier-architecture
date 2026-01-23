output "secret_managers_role" {
  description = "IAM role for EC2 to access Secrets Manager."
  value       = aws_iam_role.ec2_secrets_manager_role.name
}
