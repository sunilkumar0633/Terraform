variable "aws_region" {
  description = "AWS region for the VPC"
  type        = string
  default     = "ap-south-1"
}


variable "port_list" {
  type        = list(number)
  description = "List ssh and http"
  default     = ["80", "443", "22"]

}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type    = string
  default = "sunil_mumbai"
}
