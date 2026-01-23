# --- Security ---
resource "aws_security_group" "redis" {
  name        = "redis-sg"
  description = "Security Group for Redis replication group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "redis_ingress_backend" {
  type                     = "ingress"
  from_port                = aws_elasticache_replication_group.redis.port
  to_port                  = aws_elasticache_replication_group.redis.port
  protocol                 = "tcp"
  source_security_group_id = var.security_group_backend_id
  security_group_id        = aws_security_group.redis.id
  description              = "Allow access from backend"
}

# --- ElastiCache ---
resource "aws_elasticache_subnet_group" "redis" {
  name       = "redis-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "replication-group-redis"
  description                = "Valkey Replication Group"
  engine                     = "valkey"
  node_type                  = var.cache_node_type
  num_node_groups            = 1                        # For Cluster Mode Disabled, this is 1 shard
  replicas_per_node_group    = var.cache_node_count - 1 # e.g., 3 nodes total = 1 primary + 2 replicas
  automatic_failover_enabled = true
  port                       = 6379
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  multi_az_enabled           = true
  engine_version             = var.engine_version
}
