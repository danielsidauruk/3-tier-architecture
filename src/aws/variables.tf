variable "application_name" {
  type        = string
  description = "The name of the application or project."
}

variable "primary_region" {
  type        = string
  description = "The primary AWS region for resource deployment."
}

# VPC
variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block of the VPC where resources will be deployed."
}

variable "az_count" {
  type        = number
  description = "Number of Availability Zones."
}

# EC2
variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
}

variable "key_name" {
  description = "The name of the key pair to use for the instances."
  type        = string
}

variable "repo_url" {
  description = "The URL of the repository to be cloned."
  type        = string
}

# Frontend App
variable "frontend_desired_capacity" {
  description = "The desired number of instances in the ASG."
  type        = number
}

variable "frontend_max_size" {
  description = "The maximum number of instances in the ASG."
  type        = number
}

variable "frontend_min_size" {
  description = "The minimum number of instances in the ASG."
  type        = number
}

# Backend App
variable "backend_desired_capacity" {
  description = "The desired number of instances in the ASG."
  type        = number
}

variable "backend_max_size" {
  description = "The maximum number of instances in the ASG."
  type        = number
}

variable "backend_min_size" {
  description = "The minimum number of instances in the ASG."
  type        = number
}

variable "backend_app_port" {
  description = "The port the backend application listens on."
  type        = string
}

# DocumentDB
variable "mongodb_username" {
  description = "Master username for the DocumentDB cluster."
  type        = string
}

variable "db_node_type" {
  description = "The instance type for the DocumentDB nodes."
  type        = string
}

variable "db_node_count" {
  description = "The number of DocumentDB nodes."
  type        = number
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
