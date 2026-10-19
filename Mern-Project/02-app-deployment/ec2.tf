# 1. Security Group 

resource "aws_security_group" "app_server_sg" {
  name        = "society-app-server-sg"
  description = "allow ssh and http"
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
    description = "outbound rules"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "SocietyManagement"
    Env     = "Prod"
  }
}

# 2. Ec2 - server

resource "aws_instance" "app_server" {
  ami                         = data.aws_ami.rhel9.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.selected.id
  vpc_security_group_ids      = [aws_security_group.app_server_sg.id]
  key_name                    = var.key_name
  user_data                   = file("${path.module}/userdata.sh")
  user_data_replace_on_change = true
  iam_instance_profile        = aws_iam_instance_profile.app_profile.name

  tags = {
    Project = "SocietyManagement"
    Env     = "Prod"
  }
}

# 3 IAM Role for ec2

resource "aws_iam_role" "app_server_role" {
  name = "society-app-ec2-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project = "SocietyManagement"
    Env     = "Prod"
  }
}

# 4. Secret manager access policy

resource "aws_iam_role_policy" "secrets_access" {
  name = "society-app-secrets-access"
  role = aws_iam_role.app_server_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = data.aws_secretsmanager_secret.app_config.arn
      }
    ]
  })
}

# 5. IAM Instance Profile

resource "aws_iam_instance_profile" "app_profile" {
  name = "society-app-instnace-profile"
  role = aws_iam_role.app_server_role.name
}
