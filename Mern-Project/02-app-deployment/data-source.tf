
# --------------------------------------------------
# 1. Latest RHEL 9 AMI
# --------------------------------------------------

data "aws_ami" "rhel9" {
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["RHEL-9.8.0_HVM_GA-20260521-x86_64-0-Hourly2-GP3"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# --------------------------------------------------
# 2. Default VPC
# --------------------------------------------------

data "aws_vpc" "default" {
  default = true
}


# --------------------------------------------------
# 3. Subnets in the Default VPC
# --------------------------------------------------

data "aws_subnets" "default_vpc" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}


# --------------------------------------------------
# 4. Select one Default Subnet
# --------------------------------------------------

data "aws_subnet" "selected" {
  id = sort(data.aws_subnets.default_vpc.ids)[0]
}


# --------------------------------------------------
# 5. Existing Secrets Manager Secret
# --------------------------------------------------

data "aws_secretsmanager_secret" "app_config" {
  name = "society-app/production"
}
