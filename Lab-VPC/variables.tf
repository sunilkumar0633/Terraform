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

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = map(string)

  default = {
    private_1 = "10.0.64.0/18"
    private_2 = "10.0.128.0/18"
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
