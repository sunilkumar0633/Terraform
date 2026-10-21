output "secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.app_config.name
}

output "secret_arn" {
  description = "ARN used by the EC2 IAM policy"
  value       = aws_secretsmanager_secret.app_config.arn
}
