// password for mongodb master
resource "random_password" "master_password" {
  length           = 16
  special          = true
  override_special = "!#&*()-_+[]{}<>"
}

resource "aws_secretsmanager_secret" "mongodb_secret" {
  name                    = "mongodb-secret"
  description             = "DocumentDB master user password"
  recovery_window_in_days = 0

  tags = {
    Name             = "${var.application_name}-mongodb-secret"
    application_name = var.application_name
  }
}

resource "aws_secretsmanager_secret_version" "mongodb_password" {
  secret_id     = aws_secretsmanager_secret.mongodb_secret.id
  secret_string = random_password.master_password.result
}

// subnet group for mongodb cluster
resource "aws_docdb_subnet_group" "main" {
  name       = "mongodb-subnetgroup"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "mongodb" {
  name        = "${var.application_name}-mongodb-sg"
  description = "Security group for DocumentDB cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name             = "${var.application_name}-mongodb-sg"
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

resource "aws_docdb_cluster" "mongodb" {
  cluster_identifier      = "mongodbcluster"
  engine                  = "docdb"
  engine_version          = var.engine_version
  master_username         = var.mongodb_username
  availability_zones      = var.availability_zones
  master_password         = random_password.master_password.result
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_docdb_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.mongodb.id]
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  storage_encrypted       = true
  apply_immediately       = true

  tags = {
    Name             = "${var.application_name}-mongodb-cluster"
    application_name = var.application_name
  }
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = var.db_node_count
  identifier         = "docdb-cluster-instnace-${count.index}"
  cluster_identifier = aws_docdb_cluster.mongodb.id
  instance_class     = var.db_node_type
}
