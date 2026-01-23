
# --- Networking ---
module "network" {
  source = "./modules/network"

  cidr_block     = var.cidr_block
  az_count       = var.az_count
  primary_region = var.primary_region
  security_group_backend_id = module.backend.security_group_id
}

# --- IAM ---
module "iam" {
  source = "./modules/iam"

  mongodb_secret_arn = module.documentdb.secret_arn
}

# --- Backend ---
module "backend" {
  source = "./modules/backend"

  key_name         = var.key_name
  instance_type    = var.instance_type
  primary_region   = var.primary_region
  mongodb_user     = var.mongodb_username
  backend_app_port = var.backend_app_port
  repo_url         = var.repo_url
  desired_capacity = var.backend_desired_capacity
  max_size         = var.backend_max_size
  min_size         = var.backend_min_size

  vpc_id                     = module.network.vpc_id
  private_subnet_ids         = module.network.private_subnet_ids
  security_group_frontend_id = module.frontend.security_group_id
  security_group_mongodb_id  = module.documentdb.security_group_id
  mongodb_port               = module.documentdb.port
  mongodb_endpoint           = module.documentdb.endpoint
  secret_name                = module.documentdb.secret_name
  security_group_redis_id    = module.elasticache.security_group_id
  redis_port                 = module.elasticache.port
  redis_primary_endpoint     = module.elasticache.primary_endpoint_address
  redis_reader_endpoint      = module.elasticache.reader_endpoint_address
  secret_managers_role       = module.iam.secret_managers_role
}

# --- Frontend ---
module "frontend" {
  source = "./modules/frontend"

  key_name         = var.key_name
  instance_type    = var.instance_type
  repo_url         = var.repo_url
  backend_app_port = var.backend_app_port
  desired_capacity = var.frontend_desired_capacity
  max_size         = var.frontend_max_size
  min_size         = var.frontend_min_size

  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  be_lb_dns         = module.backend.lb_dns
}

# --- DocumentDB ---
module "documentdb" {
  source = "./modules/documentdb"

  mongodb_username = var.mongodb_username
  db_node_type     = var.db_node_type
  db_node_count    = var.db_node_count

  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_subnet_ids
  security_group_backend_id = module.backend.security_group_id
  availability_zones        = module.network.availability_zones
}

# --- ElastiCache ---
module "elasticache" {
  source = "./modules/elasticache"

  cache_node_type  = var.cache_node_type
  cache_node_count = var.cache_node_count

  vpc_id                    = module.network.vpc_id
  private_subnet_ids        = module.network.private_subnet_ids
  security_group_backend_id = module.backend.security_group_id
}
