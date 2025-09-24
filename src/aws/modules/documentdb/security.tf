
resource "aws_security_group" "mongodb" {
  name        = "mongodb-sg"
  description = "Security group for DocumentDB cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name             = "mongodb-sg"
    application_name = var.application_name
  }
}

resource "aws_security_group_rule" "mongodb_ingress_backend" {
  type                     = "ingress"
  from_port                = aws_docdb_cluster.mongodb.port
  to_port                  = aws_docdb_cluster.mongodb.port
  protocol                 = "tcp"
  source_security_group_id = var.security_group_backend_id
  security_group_id        = aws_security_group.mongodb.id
  description              = "Allow access from backend"
}
