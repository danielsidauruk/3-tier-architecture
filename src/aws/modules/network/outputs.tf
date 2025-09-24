output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "list of private subnet ids."
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "public_subnet_ids" {
  description = "list of public subnet ids."
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "availability_zones" {
  description = "A list of Availability Zones for the VPC."
  value       = local.azs_random
}
