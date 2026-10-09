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

resource "aws_instance" "web" {
  ami                    = "ami-00adafae70b8029d8"
  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = "sunil_iam"
  user_data = templatefile("user_data.sh.tmp", {
    name        = "sunil"
    surename    = "kumar"
    team_member = ["manan", "punit", "Deepak", "Vibhanshi"]
  })
  user_data_replace_on_change = true
  tags = {
    "Name" = "web"
  }
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_eip" "web" {
  domain   = "vpc"
  instance = aws_instance.web.id
  tags = {
    "Name" = "web"
  }
}



resource "aws_security_group" "web" {
  name   = "web-server"
  vpc_id = aws_default_vpc.default.id

  dynamic "ingress" {
    for_each = ["22", "80", "443", "8080"]
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
    Name = "allow_ssh"
  }
}
