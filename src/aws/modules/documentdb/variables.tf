# General
variable "application_name" {
  type        = string
  description = "The name of the application or project."
}

# DocumentDB Cluster
variable "mongodb_username" {
  description = "The username for the DocumentDB cluster."
  type        = string
}

variable "engine_version" {
  description = "The DocumentDB engine version."
  type        = string
  default     = "4.0.0"
}

variable "db_node_type" {
  description = "The instance type for the DocumentDB nodes."
  type        = string
}

variable "db_node_count" {
  description = "The number of DocumentDB nodes."
  type        = number
}

# Backup
variable "backup_retention_period" {
  description = "The days to retain backups for."
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Daily time range for automated backups."
  type        = string
  default     = "03:00-05:00"
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

variable "availability_zones" {
  description = "A list of Availability Zones for the DocumentDB cluster."
  type        = list(string)
}

# Security
variable "security_group_backend_id" {
  description = "The security group ID of the backend service."
  type        = string
}