
resource "aws_docdb_subnet_group" "main" {
  name       = "mongodb-subnetgroup"
  subnet_ids = var.private_subnet_ids
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
  identifier         = "docdb-cluster-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.mongodb.id
  instance_class     = var.db_node_type
}
