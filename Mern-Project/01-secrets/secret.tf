resource "aws_secretsmanager_secret" "app_config" {
  name        = "society-app/production"
  description = "Backend environment configuration"

  tags = {
    Project     = "SocietyManagement"
    Environment = "Production"
  }
}

resource "aws_secretsmanager_secret_version" "app_config" {
  secret_id = aws_secretsmanager_secret.app_config.id

  secret_string_wo = jsonencode({
    MONGODB_URI       = "mongodb://127.0.0.1:27017/society_db"
    JWT_SECRET_STRING = var.jwt_secret_string
    JWT_EXPIRES_IN    = "7d"

    SMTP_HOST     = "smtp.gmail.com"
    SMTP_PORT     = "587"
    SMTP_USER     = var.smtp_user
    SMTP_PASSWORD = var.smtp_password

    CLIENT_URL = "https://devopsai.fun"
  })

  secret_string_wo_version = 1
}
