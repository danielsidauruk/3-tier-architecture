output "endpoint" {
  description = "Redis ElastiCache endpoint."
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "port" {
  description = "The port for Redis."
  value       = aws_elasticache_cluster.redis.port
}

output "security_group_id" {
  description = "The ID of the Redis security group."
  value       = aws_security_group.redis.id
}
