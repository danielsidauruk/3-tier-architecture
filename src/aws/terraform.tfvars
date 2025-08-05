application_name = "3-tier-architecture"
primary_region   = "ap-southeast-1"
vpc_cidr_block   = "10.0.0.0/21"
az_count         = 3

instance_type    = "t2.micro"
key_name         = "private-key"
backend_app_port = 5000
repo_url         = "https://github.com/danielsidauruk/3-tier-architecture.git"

mongodb_username = "mongodbadmin"
db_node_type     = "db.t3.medium"
db_node_count    = 1

cache_node_type  = "cache.t3.micro"
cache_node_count = 1

backend_desired_capacity  = 1
backend_max_size          = 1
backend_min_size          = 1
frontend_desired_capacity = 1
frontend_max_size         = 1
frontend_min_size         = 1
