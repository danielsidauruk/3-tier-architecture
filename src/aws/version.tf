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
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.primary_region
}
