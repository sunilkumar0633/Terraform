
# --------------------------------------------------
# 1. Security Group with Dynamic Ingress
# --------------------------------------------------

resource "aws_security_group" "app_server_sg" {
  name        = "society-app-server-sg"
  description = "SSH and HTTP access for Society App"
  vpc_id      = data.aws_vpc.default.id

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
    description = "Outbound internet access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "society-app-server-sg"
    Project = "SocietyManagement"
  }
}


# --------------------------------------------------
# 2. IAM Role for EC2
# --------------------------------------------------

resource "aws_iam_role" "app_server_role" {
  name = "society-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ec2.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "SocietyManagement"
  }
}


# --------------------------------------------------
# 3. Secrets Manager Access Policy
# --------------------------------------------------

resource "aws_iam_role_policy" "secrets_access" {
  name = "society-app-secrets-access"
  role = aws_iam_role.app_server_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "secretsmanager:GetSecretValue"
      ]

      Resource = data.aws_secretsmanager_secret.app_config.arn
    }]
  })
}


# --------------------------------------------------
# 4. IAM Instance Profile
# --------------------------------------------------

resource "aws_iam_instance_profile" "app_profile" {
  name = "society-app-instance-profile"
  role = aws_iam_role.app_server_role.name
}


# --------------------------------------------------
# 5. RHEL 9 EC2 Instance
# --------------------------------------------------

resource "aws_instance" "app_server" {
  ami           = data.aws_ami.rhel9.id
  instance_type = var.instance_type

  subnet_id                   = data.aws_subnet.selected.id
  vpc_security_group_ids      = [aws_security_group.app_server_sg.id]
  associate_public_ip_address = true

  key_name = var.key_name

  iam_instance_profile = aws_iam_instance_profile.app_profile.name

  # Execute backend setup during initial boot
  user_data = file("${path.module}/userdata.sh")

  # Replace instance if User Data changes
  user_data_replace_on_change = true

  # Require IMDSv2
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = "society-app-backend"
    Project     = "SocietyManagement"
    Environment = "Production"
  }

  depends_on = [
    aws_iam_role_policy.secrets_access
  ]
}


# --------------------------------------------------
# 6. Outputs
# --------------------------------------------------

output "app_server_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}

output "app_server_public_ip" {
  description = "Public IP of the application server"
  value       = aws_instance.app_server.public_ip
}

output "app_server_public_dns" {
  description = "Public DNS of the application server"
  value       = aws_instance.app_server.public_dns
}

output "selected_rhel_ami_id" {
  description = "RHEL 9 AMI selected by Terraform"
  value       = data.aws_ami.rhel9.id
}

output "selected_vpc_id" {
  description = "Selected default VPC ID"
  value       = data.aws_vpc.default.id
}

output "selected_subnet_id" {
  description = "Selected default subnet ID"
  value       = data.aws_subnet.selected.id
}

output "app_secret_arn" {
  description = "Secrets Manager ARN"
  value       = data.aws_secretsmanager_secret.app_config.arn
}
