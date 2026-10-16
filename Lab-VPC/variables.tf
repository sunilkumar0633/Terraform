
variable "aws_region" {
  description = "AWS region for the VPC"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.0.0/18"
}

variable "public_az" {
  description = "Availability Zone for the public subnet"
  type        = string
  default     = "ap-south-1a"
}

variable "private_subnets" {
  description = "Private subnet configuration by Availability Zone"

  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))

  default = {
    private_1 = {
      cidr_block        = "10.0.64.0/18"
      availability_zone = "ap-south-1a"
    }

    private_2 = {
      cidr_block        = "10.0.128.0/18"
      availability_zone = "ap-south-1b"
    }
  }
}

variable "common_tags" {
  description = "Common tags for network resources"
  type        = map(string)

  default = {
    Environment = "test"
    Project     = "society-management"
    ManagedBy   = "Terraform"
  }
}
