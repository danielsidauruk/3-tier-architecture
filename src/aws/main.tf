resource "aws_resourcegroups_group" "main" {
  name = var.application_name

  resource_query {
    query = jsonencode(
      {
        ResourceTypeFilters = [
          "AWS::AllSupported"
        ]
        TagFilters = [
          {
            Key    = "application"
            Values = [var.application_name]
          }
        ]
      }
    )
  }
}

module "vpc" {

  source = "./modules/vpc"

  application_name = var.application_name
  vpc_cidr_block   = var.vpc_cidr_block
  az_count         = var.az_count

}

module "backend" {

  source = "./modules/backend"

  application_name = var.application_name
  key_name         = var.key_name
  backend_app_port = var.backend_app_port
  instance_type    = var.instance_type
  primary_region   = var.primary_region
  mongodb_user     = var.mongodb_username
  repo_url         = var.repo_url

  vpc_id                     = module.vpc.vpc_id
  private_subnet_ids         = module.vpc.private_subnet_ids
  security_group_frontend_id = module.frontend.security_group_frontend_id
  security_group_mongodb_id  = module.documentdb.security_group_mongodb_id
  mongodb_port               = module.documentdb.mongodb_port
  mongodb_endpoint           = module.documentdb.mongodb_endpoint
  mongodb_secret_arn         = module.documentdb.mongodb_secret_arn
  secret_name                = module.documentdb.secret_name
  security_group_redis_id    = module.elasticache.security_group_redis_id
  redis_port                 = module.elasticache.redis_port
  redis_endpoint             = module.elasticache.redis_endpoint

}


module "frontend" {

  source = "./modules/frontend"

  application_name = var.application_name
  key_name         = var.key_name
  instance_type    = var.instance_type
  repo_url         = var.repo_url
  backend_app_port = var.backend_app_port

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  backend_private_ip = module.backend.backend_private_ip

}


module "documentdb" {

  source = "./modules/documentdb"

  application_name = var.application_name
  mongodb_username = var.mongodb_username
  db_node_type     = var.db_node_type
  db_node_count    = var.db_node_count

  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  security_group_backend_id = module.backend.security_group_backend_id
  availability_zones        = module.vpc.availability_zones

}


module "elasticache" {

  source = "./modules/elasticache"

  application_name = var.application_name
  cache_node_type  = var.cache_node_type
  cache_node_count = var.cache_node_count

  private_subnet_ids        = module.vpc.private_subnet_ids
  vpc_id                    = module.vpc.vpc_id
  security_group_backend_id = module.backend.security_group_backend_id

}
