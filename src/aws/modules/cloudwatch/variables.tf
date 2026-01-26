
variable "asg_backend" {
  description = "Name of the Auto Scaling group."
  type        = string
}

variable "asg_frontend" {
  description = "Name of the frontend Auto Scaling group."
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region."
  type        = string
}

variable "lb_backend_name" {
  description = "Name of the backend load balancer."
  type        = string
}

variable "lb_backend_arn_suffix" {
  description = "ARN suffix of the backend load balancer."
  type        = string
}

variable "lb_frontend_name" {
  description = "Name of the frontend load balancer."
  type        = string
}

variable "lb_frontend_arn_suffix" {
  description = "ARN suffix of the frontend load balancer."
  type        = string
}

variable "docdb_cluster_identifier" {
  description = "DocumentDB cluster identifier."
  type        = string
}

variable "elasticache_cluster_id" {
  description = "ElastiCache cluster ID."
  type        = string
}

variable "nat_gateway_id" {
  description = "NAT gateway ID."
  type        = string
}

variable "elasticache_member_clusters" {
  description = "ElastiCache Member Clusters"
  type        = list(string)
}