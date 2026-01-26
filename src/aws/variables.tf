variable "primary_region" {
  type        = string
  description = "Primary AWS region for deployment."
}

# VPC
variable "cidr_block" {
  type        = string
  description = "VPC CIDR block."
}

variable "az_count" {
  type        = number
  description = "Number of Availability Zones."
}

# EC2
variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "key_name" {
  description = "Key pair name for EC2."
  type        = string
}

variable "repo_url" {
  description = "Repository URL."
  type        = string
}

# Frontend App
variable "frontend_desired_capacity" {
  description = "Desired instances in the ASG."
  type        = number
}

variable "frontend_max_size" {
  description = "Maximum instances in the ASG."
  type        = number
}

variable "frontend_min_size" {
  description = "Minimum instances in the ASG."
  type        = number
}

# Backend App
variable "backend_desired_capacity" {
  description = "Desired instances in the ASG."
  type        = number
}

variable "backend_max_size" {
  description = "Maximum instances in the ASG."
  type        = number
}

variable "backend_min_size" {
  description = "Minimum instances in the ASG."
  type        = number
}

variable "backend_app_port" {
  description = "Backend application port."
  type        = string
}

# DocumentDB
variable "mongodb_username" {
  description = "DocumentDB master username."
  type        = string
}

variable "db_node_type" {
  description = "DocumentDB node instance type."
  type        = string
}

variable "db_node_count" {
  description = "Number of DocumentDB nodes."
  type        = number
}

# ElastiCache
variable "cache_node_type" {
  description = "ElastiCache node instance type."
  type        = string
}

variable "cache_node_count" {
  description = "Number of ElastiCache nodes."
  type        = number
}

