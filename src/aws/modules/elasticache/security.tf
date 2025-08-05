
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
