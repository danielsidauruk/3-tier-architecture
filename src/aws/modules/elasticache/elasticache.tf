
resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.application_name}-redis-subnet-group"
    application = var.application_name
  }
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "replication-group-redis"
  description                = "Valkey replication group for ${var.application_name}"
  engine                     = "valkey"
  node_type                  = var.cache_node_type
  num_node_groups            = 1                        # For Cluster Mode Disabled, this is 1 shard
  replicas_per_node_group    = var.cache_node_count - 1 # e.g., 3 nodes total = 1 primary + 2 replicas
  automatic_failover_enabled = true
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  # engine_version             = "7.2" # Specify a valid Valkey version

  tags = {
    Name        = "${var.application_name}-redis"
    application = var.application_name
  }
}
