output "mongodb_endpoint" {
  description = "The cluster endpoint."
  value       = aws_docdb_cluster.mongodb.endpoint
}

output "mongodb_port" {
  description = "The cluster port."
  value       = aws_docdb_cluster.mongodb.port
}

output "security_group_mongodb_id" {
  description = "The ID of the security group created for the DocumentDB cluster."
  value       = aws_security_group.mongodb.id
}

output "secret_name" {
  description = "The ARN of the Secrets Manager secret storing DocumentDB credentials."
  value       = aws_secretsmanager_secret.mongodb_secret.name
}

output "mongodb_secret_arn" {
  description = "The ARN of the secret containing the DocumentDB credentials."
  value       = aws_secretsmanager_secret.mongodb_secret.arn
}
