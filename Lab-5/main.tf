terraform {
  required_version = "~>1.16.0"
  required_providers {
    aws = {
      version = "6.67.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1.  Create RDS 
resource "aws_db_instance" "prod" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.4.8"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = aws_ssm_parameter.rds_password.value
  parameter_group_name = "default.mysql8.4"
  skip_final_snapshot  = true
  apply_immediately    = true
}

# 2. Generate password 
resource "random_password" "main" {
  length           = 20
  special          = true
  override_special = "#!()_"
}

# 3.  Store it in SSM Parameter Store 
resource "aws_ssm_parameter" "rds_password" {
  name        = "/prod/prod-mysql-rds/password"
  description = "Master password for the RDS database"
  type        = "SecureString"
  value       = random_password.main.result
}

# 4 Read the stored parameter 
# This data source reads/decrypts the value; state may contain it. 
data "aws_ssm_parameter" "rds_password" {
  name       = aws_ssm_parameter.rds_password.name
  depends_on = [aws_ssm_parameter.rds_password]
}

#------------------------------------------------------------------------------------------------
output "rds_address" {
  value = aws_db_instance.prod.address
}
output "rds_port" {
  value = aws_db_instance.prod.port
}
output "rds_username" {
  value = aws_db_instance.prod.username
}

output "rds_password" {
  value     = aws_ssm_parameter.rds_password.value
  sensitive = true
}
