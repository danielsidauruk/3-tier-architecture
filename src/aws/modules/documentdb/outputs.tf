output "endpoint" {
  description = "The cluster endpoint."
  value       = aws_docdb_cluster.mongodb.endpoint
}

output "port" {
  description = "DocumentDB cluster port."
  value       = aws_docdb_cluster.mongodb.port
}

output "security_group_id" {
  description = "DocumentDB cluster security group ID."
  value       = aws_security_group.mongodb.id
}

output "secret_name" {
  description = "Secrets Manager name."
  value       = aws_secretsmanager_secret.mongodb_secret.name
}

output "secret_arn" {
  description = "Secrets Manager arn."
  value       = aws_secretsmanager_secret.mongodb_secret.arn
}
