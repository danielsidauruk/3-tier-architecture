variable "application_name" {
  type        = string
  description = "Application's name."
}

# Instance
variable "cache_node_type" {
  description = "The instance type for the ElastiCache nodes."
  type        = string
}

variable "cache_node_count" {
  description = "The number of ElastiCache nodes."
  type        = number
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

variable "security_group_backend_id" {
  description = "The security group ID of the backend service."
  type        = string
}
