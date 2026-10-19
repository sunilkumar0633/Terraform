variable "aws_region" {
  description = "AWS region for the VPC"
  type        = string
  default     = "ap-south-1"
}

variable "smtp_user" {
  description = "SMTP Email Address"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "smtp_password" {
  description = "SMTP App Pass"
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "jwt_secret_string" {
  description = "JWT String"
  type        = string
  sensitive   = true
  ephemeral   = true
}
