output "primary_endpoint_address" {
  description = "Primary endpoint address for Valkey replication group."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Reader endpoint address for Redis replication group."
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
}

output "port" {
  description = "Redis port."
  value       = aws_elasticache_replication_group.redis.port
}

output "security_group_id" {
  description = "Redis security group ID."
  value       = aws_security_group.redis.id
}

output "cluster_id" {
  description = "ElastiCache cluster ID."
  value       = aws_elasticache_replication_group.redis.replication_group_id
}

output "member_clusters" {
  description = "Member Clusters"
  value       = aws_elasticache_replication_group.redis.member_clusters
}
