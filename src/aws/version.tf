terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }

  backend "s3" {
    bucket  = "3-tier-architecture-tfstate"
    region  = "ap-southeast-1"
    key     = "dev/aws/terraform.tfstate"
    encrypt = true
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.primary_region
}