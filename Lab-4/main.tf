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

resource "aws_default_vpc" "default" {

}

resource "aws_instance" "web-server" {
  ami                         = "ami-00adafae70b8029d8"
  instance_type               = "t3.small"
  vpc_security_group_ids      = [aws_security_group.common.id]
  key_name                    = "sunil_iam"
  user_data                   = file("user-data.sh")
  user_data_replace_on_change = true
  tags = {
    "Name" = "web"
  }

  depends_on = [aws_instance.app-server, aws_instance.db-server]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "app-server" {
  ami                         = "ami-00adafae70b8029d8"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.common.id]
  key_name                    = "sunil_iam"
  user_data_replace_on_change = true
  tags = {
    "Name" = "app"
  }

  depends_on = [aws_instance.db-server]

}

resource "aws_instance" "db-server" {
  ami                         = "ami-00adafae70b8029d8"
  instance_type               = "t3.micro"
  vpc_security_group_ids      = [aws_security_group.common.id]
  key_name                    = "sunil_iam"
  user_data_replace_on_change = true
  tags = {
    "Name" = "db"
  }

}



resource "aws_security_group" "common" {
  name   = "web-app-db-server"
  vpc_id = aws_default_vpc.default.id

  dynamic "ingress" {
    for_each = ["22", "80", "443", "8080", "3306"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }

  egress {
    description = "allow all traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_http_mysql"
  }
}


#-----------------------------------------------
#Print Resource Details

output "common_securitygroup_id" {
  description = "Security group ID"
  value       = aws_security_group.common.id

}

#Print web-server Private IP

output "web_server_private_IP" {
  description = "Print web -server IP"
  value       = aws_instance.web-server.private_ip

}

#Print app-server Private IP

output "app_server_private_IP" {
  description = "Print app-server IP"
  value       = aws_instance.app-server.private_ip

}

#Print app-servers ID

output "Instances_IDs" {
  description = "Print all-server Instance IDs"
  value = [
    aws_instance.web-server.id,
    aws_instance.app-server.id,
    aws_instance.db-server.id
  ]

}
