
terraform {
  required_version = "~> 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.67.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Default VPC
resource "aws_default_vpc" "default" {}

# Security Group
resource "aws_security_group" "web" {
  name   = "web-server"
  vpc_id = aws_default_vpc.default.id

  dynamic "ingress" {
    for_each = var.port_list

    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# EC2 Instance
resource "aws_instance" "web-1" {
  ami                    = "ami-0a29987e14ae814db"
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_pair

  tags = {
    Name = "web"
  }
}

# Run Nginx setup whenever nginx.sh changes
resource "terraform_data" "nginx" {
  triggers_replace = [
    filesha256("${path.module}/nginx.sh")
  ]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.ssh_key)
    host        = aws_instance.web-1.public_ip
  }

  # Copy script to EC2
  provisioner "file" {
    source      = "${path.module}/nginx.sh"
    destination = "/tmp/nginx.sh"
  }

  # Execute script on EC2
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/nginx.sh",
      "sudo bash /tmp/nginx.sh",
      "sudo nginx -t",
      "sudo nginx -t > /tmp/nginx_conf_output 2>&1"
    ]
  }

  # Download the result to the local machine
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = "'cat /tmp/nginx_conf_output' > '${path.module}/nginx_conf_output.txt'"
  }

  depends_on = [
    aws_instance.web-1
  ]
}
