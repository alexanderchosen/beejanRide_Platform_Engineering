# since, i did not use Fargate to manage the AWS server
# i have to consider auto scaling group, launch template, assign IAM, and a provider


variable "name_prefix" {
  type = string
}

variable "purpose" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "min_size" {
  type = number
  default = 1
}

variable "max_size" {
  type = number
  default = 1
}

variable "desired_capacity" {
  type = number
  default = 1
}

variable "container_image" {
  type = string
}

variable "container_port" {
  type = number
}

variable "task_cpu" {
  type = number
  default = 256
}

variable "task_memory" {
  type = number
  default = 256
}

variable "desired_count" {
  type = number
  default = 1
}

variable "allowed_ingress_cidr" {
  type = string
}

variable "s3_read_arn" {
  type = list(string)
  default = []
}

variable "s3_write_arn" {
  type = list(string)
  default = []
}

variable "secrets_read_arn" {
  type = list(string)
  default = []
}