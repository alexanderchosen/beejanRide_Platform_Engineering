variable "name_prefix" {
  description = "This prefix will be added to the default tags I have set"
  type = string
}

variable "purpose" {
  description = "This is to give an additional short identifier for this instance to create differences in their names"
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "allowed_ingress_cidr" {
  description = "This refers to the CIDR allowed to reach the instance."
  type = string
}

variable "ingress_port" {
  type = number
  default = 22
}