# DocumentDB Cluster
variable "mongodb_username" {
  description = "DocumentDB cluster username."
  type        = string
}

variable "engine_version" {
  description = "DocumentDB engine version."
  type        = string
  default     = "4.0.0"
}

variable "db_node_type" {
  description = "DocumentDB node instance type."
  type        = string
}

variable "db_node_count" {
  description = "Number of DocumentDB nodes."
  type        = number
}

# Backup
variable "backup_retention_period" {
  description = "Days to retain backups."
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
  description = "VPC ID."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs."
  type        = list(string)
}

variable "availability_zones" {
  description = "List of Availability Zones for the DocumentDB cluster."
  type        = list(string)
}

# Security
variable "security_group_backend_id" {
  description = "Backend service security group ID."
  type        = string
}
