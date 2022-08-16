variable "cluster_name" {
  type = string
}

variable "aws_subnet_public_cidr" {
  default = [
    "192.168.0.0/19",
    "192.168.32.0/19",
    "192.168.64.0/19"
  ]
  type = list(any)
}

variable "aws_subnet_private_cidr" {
  default = [
    "192.168.96.0/19",
    "192.168.128.0/19",
    "192.168.160.0/19"
  ]
  type = list(any)
}