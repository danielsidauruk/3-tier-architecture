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
variable "backend_private_ip" {
  description = "The private IP address of the backend instance."
  type        = string
}

variable "backend_app_port" {
  description = "The port the backend application listens on."
  type        = number
}

variable "repo_url" {
  description = "The URL of the repository to be cloned."
  type        = string
}
