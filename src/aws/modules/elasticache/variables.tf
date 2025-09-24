# General
variable "application_name" {
  type        = string
  description = "Application's name."
}

# ElastiCache
variable "cache_node_type" {
  description = "The instance type for the ElastiCache nodes."
  type        = string
}

variable "cache_node_count" {
  description = "The number of ElastiCache nodes."
  type        = number
}

variable "engine_version" {
  description = "The ElastiCache Valkey engine version."
  type        = string
  default     = "8.1"
}

# Networking
variable "vpc_id" {
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs."
  type        = list(string)
}

# Security
variable "security_group_backend_id" {
  description = "The security group ID of the backend service."
  type        = string
}