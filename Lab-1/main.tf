provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "Test" {
  ami                    = "ami-0d27e0fb3bac4d724"
  instance_type          = "t3.small"
  key_name               = "sunil_iam"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "HelloWorld"
    Env  = "Test"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh traffic"
  vpc_id      = "vpc-05fd600cffb5597d3"

  ingress {
    description = "allow ssh for all"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

