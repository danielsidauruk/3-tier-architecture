
resource "aws_security_group" "backend" {
  name        = "${var.application_name}-backend-sg"
  description = "Allow traffic to/from backend application"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.security_group_frontend_id]
    description     = "Allow SSH from Frontend instances"
  }

  ingress {
    from_port       = var.backend_app_port
    to_port         = var.backend_app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_lb_sg.id]
    description     = "Allow app traffic from load balancer"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound to internet via NAT Gateway"
  }

  tags = {
    Name        = "${var.application_name}-backend-sg"
    application = var.application_name
  }
}

resource "aws_security_group_rule" "backend_egress_mongodb" {
  type                     = "egress"
  from_port                = var.mongodb_port
  to_port                  = var.mongodb_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = var.security_group_mongodb_id
  description              = "Allow outbound to DocumentDB Cluster"
}

resource "aws_security_group_rule" "backend_egress_redis" {
  type                     = "egress"
  from_port                = var.redis_port
  to_port                  = var.redis_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = var.security_group_redis_id
  description              = "Allow outbound to Redis Cluster"
}

resource "aws_security_group" "backend_lb_sg" {
  name        = "${var.application_name}-lb-sg"
  description = "Security group for the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.backend_app_port
    to_port         = var.backend_app_port
    protocol        = "tcp"
    security_groups = [var.security_group_frontend_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.application_name}-lb-sg"
    application = var.application_name
  }
}
