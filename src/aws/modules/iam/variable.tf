# Secrets Manager
variable "mongodb_secret_arn" {
  description = "ARN of the secret containing MongoDB credentials."
  type        = string
}

# variable "documentdb_arn" {
#   description = "DocumentDB's Arn"
#   type        = string
# }

# variable "elasticache_arn" {
#   description = "Elasticache's Arn"
#   type        = string
# }