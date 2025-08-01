resource "aws_security_group" "redis" {
  name        = "${var.application_name}-redis-sg"
  description = "Security Group for Redis cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.application_name}-redis-sg"
    application = var.application_name
  }
}

resource "aws_security_group_rule" "redis_ingress_backend" {
  type                     = "ingress"
  from_port                = aws_elasticache_cluster.redis.port
  to_port                  = aws_elasticache_cluster.redis.port
  protocol                 = "tcp"
  source_security_group_id = var.security_group_backend_id
  security_group_id        = aws_security_group.redis.id
  description              = "Allow access from backend"
}

// subnet group for redis cluster
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
