output "primary_endpoint_address" {
  description = "The address of the primary endpoint for the Valkey replication group."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "The address of the reader endpoint for the Redis replication group."
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "port" {
  description = "The port for Redis."
  value       = aws_elasticache_replication_group.redis.port
}

output "security_group_id" {
  description = "The ID of the Redis security group."
  value       = aws_security_group.redis.id
}
