# Networking
variable "vpc_id" {
  type        = string
  description = "VPC ID."
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs."
  type        = list(string)
}

# EC2 & ASG
variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "key_name" {
  description = "Key pair name."
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

# Application/Repo
variable "repo_url" {
  description = "Repository URL."
  type        = string
}

variable "backend_app_port" {
  description = "Backend application port."
  type        = number
}

variable "be_lb_dns" {
  description = "Backend load balancer's DNS name."
  type        = string
}
