variable "application_name" {
  type        = string
  description = "The name of the application or project."
}

variable "environment_name" {
  type        = string
  description = "The deployment environment (e.g., dev, staging, prod)."
  default     = "dev"
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block of the VPC where resources will be deployed."
}

variable "az_count" {
  type        = number
  description = "Number of Availability Zones."
}

variable "primary_region" {
  type        = string
  description = "The primary AWS region for resource deployment."
}
