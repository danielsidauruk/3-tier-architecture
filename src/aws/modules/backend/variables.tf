# General
variable "application_name" {
  description = "The name of the application."
  type        = string
}

variable "primary_region" {
  description = "The primary AWS region"
  type        = string
}

# Networking
variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs"
  type        = list(string)
}

# Security
variable "security_group_frontend_id" {
  description = "The ID of the frontend security group"
  type        = string
}

variable "security_group_mongodb_id" {
  description = "The ID of the MongoDB security group"
  type        = string
}

variable "security_group_redis_id" {
  description = "The ID of the Redis security group"
  type        = string
}

# EC2 & ASG
variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "The name of the EC2 key pair"
  type        = string
}

variable "desired_capacity" {
  description = "The desired number of instances in the ASG"
  type        = number
}

variable "max_size" {
  description = "The maximum number of instances in the ASG"
  type        = number
}

variable "min_size" {
  description = "The minimum number of instances in the ASG"
  type        = number
}

# Database & Cache
variable "mongodb_port" {
  description = "The port for MongoDB"
  type        = number
}

variable "mongodb_endpoint" {
  description = "The endpoint of the MongoDB cluster"
  type        = string
}

variable "mongodb_user" {
  description = "The username for MongoDB"
  type        = string
}

variable "redis_port" {
  description = "The port for Redis"
  type        = number
}

variable "redis_primary_endpoint" {
  description = "The endpoint of the Redis cluster"
  type        = string
}

variable "redis_reader_endpoint" {
  description = "The endpoint of the Redis cluster"
  type        = string
}

# Secrets Manager
variable "mongodb_secret_arn" {
  description = "The ARN of the secret containing the MongoDB credentials"
  type        = string
}

variable "secret_name" {
  description = "The name of the secret in AWS Secrets Manager"
  type        = string
}

# Application/Repo
variable "backend_app_port" {
  description = "The port the backend application listens on"
  type        = number
}

variable "repo_url" {
  description = "The URL of the backend repository"
  type        = string
}