variable "application_name" {
  type        = string
  description = "The name of the application or project."
}

variable "primary_region" {
  description = "The primary AWS region."
  type        = string
}

# Networking
variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs."
  type        = list(string)
}

variable "security_group_frontend_id" {
  description = "The ID of the frontend security group."
  type        = string
}

variable "security_group_mongodb_id" {
  description = "The ID of the MongoDB security group."
  type        = string
}

variable "security_group_redis_id" {
  description = "The ID of the Redis security group."
  type        = string
}

# Instance
variable "key_name" {
  description = "The name of the key pair to use for the instances."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
}

# Application
variable "repo_url" {
  description = "The URL of the repository to be cloned."
  type        = string
}

variable "backend_app_port" {
  description = "The port the backend application listens on."
  type        = number
}

variable "mongodb_endpoint" {
  description = "The endpoint for the MongoDB cluster."
  type        = string
  sensitive   = true
}

variable "mongodb_user" {
  description = "The username for the MongoDB cluster."
  type        = string
  sensitive   = true
}

variable "mongodb_port" {
  description = "The port for MongoDB."
  type        = number
}

variable "redis_endpoint" {
  description = "The endpoint for the Redis cluster."
  type        = string
  sensitive   = true
}

variable "redis_port" {
  description = "The port for Redis."
  type        = number
}

variable "secret_name" {
  description = "The name of the secret in AWS Secrets Manager."
  type        = string
}

variable "mongodb_secret_arn" {
  description = "The ARN of the secret containing the MongoDB credentials."
  type        = string
}
