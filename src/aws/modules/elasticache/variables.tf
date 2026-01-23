# ElastiCache
variable "cache_node_type" {
  description = "ElastiCache node instance type."
  type        = string
}

variable "cache_node_count" {
  description = "Number of ElastiCache nodes."
  type        = number
}

variable "engine_version" {
  description = "ElastiCache Valkey engine version."
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
  description = "Backend service security group ID."
  type        = string
}
