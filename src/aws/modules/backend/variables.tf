# General
variable "primary_region" {
  description = "Primary AWS region."
  type        = string
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
variable "security_group_frontend_id" {
  description = "Frontend security group ID."
  type        = string
}

variable "security_group_mongodb_id" {
  description = "MongoDB security group ID."
  type        = string
}

variable "security_group_redis_id" {
  description = "Redis security group ID."
  type        = string
}

# EC2 & ASG
variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name."
  type        = string
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG."
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in the ASG."
  type        = number
}

variable "min_size" {
  description = "Minimum number of instances in the ASG."
  type        = number
}

# Database & Cache
variable "mongodb_port" {
  description = "MongoDB port."
  type        = number
}

variable "mongodb_endpoint" {
  description = "MongoDB cluster endpoint."
  type        = string
}

variable "mongodb_user" {
  description = "MongoDB username."
  type        = string
}

variable "redis_port" {
  description = "Redis port."
  type        = number
}

variable "redis_primary_endpoint" {
  description = "Redis cluster endpoint."
  type        = string
}

variable "redis_reader_endpoint" {
  description = "Redis cluster endpoint."
  type        = string
}

# Secrets Manager
variable "secret_managers_role" {
  description = "Secret Manager Role."
  type        = string
}

variable "secret_name" {
  description = "AWS Secrets Manager secret name."
  type        = string
}

# Application/Repo
variable "backend_app_port" {
  description = "Backend application port."
  type        = number
}

variable "repo_url" {
  description = "Backend repository URL."
  type        = string
}