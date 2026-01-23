# General
variable "primary_region" {
  description = "Primary AWS region."
  type        = string
}

# VPC
variable "cidr_block" {
  type        = string
  description = "CIDR block."
}

variable "az_count" {
  description = "Number of Availability Zones."
  type        = number
}

# Security
variable "security_group_backend_id" {
  description = "Backend Security Group ID."
  type        = string
}
