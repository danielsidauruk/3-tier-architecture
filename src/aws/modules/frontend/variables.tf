# General
variable "application_name" {
  type        = string
  description = "The name of the application or project."
}

# Networking
variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs."
  type        = list(string)
}

# EC2 & ASG
variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
}

variable "key_name" {
  description = "The name of the key pair to use for the instances."
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

# Application/Repo
variable "repo_url" {
  description = "The URL of the repository to be cloned."
  type        = string
}

variable "backend_app_port" {
  description = "The port the backend application listens on."
  type        = number
}

variable "be_lb_dns" {
  description = "The DNS name of the load balancer"
  type        = string
}