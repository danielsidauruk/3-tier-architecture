resource "aws_resourcegroups_group" "main" {
  name = "${var.application_name}-${var.environment_name}"

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
          },
          {
            Key    = "environment"
            Values = [var.environment_name]
          }
        ]
      }
    )
  }
}

module "vpc" {
  source = "./modules/vpc"

  application_name = var.application_name
  environment_name = var.environment_name
  vpc_cidr_block   = var.vpc_cidr_block
  az_count         = var.az_count
}
