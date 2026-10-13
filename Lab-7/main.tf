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
  password_wo          = ephemeral.aws_secretsmanager_secret_version.rds_password.secret_string
  password_wo_version  = aws_secretsmanager_secret_version.rds_password.secret_string_wo_version
  parameter_group_name = "default.mysql8.4"
  skip_final_snapshot  = true
  apply_immediately    = true
}

# 2. Generate password 
ephemeral "random_password" "main" {
  length           = 20
  special          = true
  override_special = "#!()_"
}

# 3. Create the Secrets Manager secret container 
resource "aws_secretsmanager_secret" "rds_password" {
  name                    = "/prod/rds/password"
  description             = "Password for the RDS database"
  recovery_window_in_days = 0
}


# 4. Store a secret version 
resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id                = aws_secretsmanager_secret.rds_password.id
  secret_string_wo         = ephemeral.random_password.main.result
  secret_string_wo_version = 1
}



# 5. Read the current secret version 
# The decrypted secret may be recorded in Terraform state. 
ephemeral "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = aws_secretsmanager_secret_version.rds_password.secret_id
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


