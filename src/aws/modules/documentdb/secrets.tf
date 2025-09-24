
resource "random_password" "master_password" {
  length           = 16
  special          = true
  override_special = "!#&*()-_+[]{}<>"
}

resource "aws_secretsmanager_secret" "mongodb_secret" {
  name                    = "mongodb-secret"
  description             = "DocumentDB master user password"
  recovery_window_in_days = 0

  tags = {
    Name             = "mongodb-secret"
    application_name = var.application_name
  }
}

resource "aws_secretsmanager_secret_version" "mongodb_password" {
  secret_id     = aws_secretsmanager_secret.mongodb_secret.id
  secret_string = random_password.master_password.result
}
