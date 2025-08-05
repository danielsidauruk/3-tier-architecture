
resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnetgroup"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "rediscluster"
  engine               = "redis"
  engine_version       = "6.x"
  node_type            = var.cache_node_type
  num_cache_nodes      = var.cache_node_count
  parameter_group_name = "default.redis6.x"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]

  tags = {
    Name        = "${var.application_name}-redis"
    application = var.application_name
  }
}
