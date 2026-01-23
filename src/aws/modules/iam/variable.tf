# Secrets Manager
variable "mongodb_secret_arn" {
  description = "ARN of the secret containing MongoDB credentials."
  type        = string
}
