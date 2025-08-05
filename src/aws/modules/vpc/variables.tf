# General
variable "application_name" {
  type        = string
  description = "The name of the application or project."
}

variable "primary_region" {
  description = "The primary AWS region."
  type        = string
}

# VPC
variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block of the VPC where resources will be deployed."
}

variable "az_count" {
  description = "The number of availability zones to use."
  type        = number
}

# Security
variable "security_group_backend_id" {
  description = "The ID of the Backend security group."
  type        = string
}
