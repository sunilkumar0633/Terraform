variable "aws_region" {
  type        = string
  description = "aws region"
  default     = "us-east-1"
}

variable "instance_type" {
  type        = string
  description = "ec2-instance size"
  default     = "t3.small"
}

variable "key_pair" {
  type        = string
  description = "SSH key pair name Public key"
  default     = "sunil_iam"
}

variable "ssh_key" {
  type        = string
  description = "SSH key pair name Private key"
  default     = "C:/Users/Dell/Downloads/sunil_iam.pem"
}

variable "port_list" {
  type        = list(number)
  description = "List of ports"
  default     = ["80", "443", "22"]
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply on resources"
  default = {
    Name = "web"
    Env  = "Prod"
  }
}
