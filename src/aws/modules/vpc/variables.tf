variable "application_name" {
  type        = string
  description = "The name of the application or project."
}

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block of the VPC where resources will be deployed."
}

variable "az_count" {
  type        = number
  description = "Number of Availability Zones."
}
