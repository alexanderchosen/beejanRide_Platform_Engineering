variable "name_prefix" {
  description = "Prefix used for naming the role"
  type = string
}

variable "role-use" {
  description = "This describes the role use so as to distinguish roles from another"
  type = string
}

variable "trusted_service" {
  description = "For this project, the ecs and ec2 services are the only services trusted to use this service"
  type = string

  validation {
    condition = contains(["ecs-tasks", "ec2"], var.trusted_service)
    error_message = "trusted_service must be either an ecs-tasks or ec2."
  }
}


# so, i had to encourage least-privilege access by restricting wildcard access to the resources ("*")

variable "s3_read_arn" {
  description = "This is to validate the S3 bucket/object ARNs this role can read from"
  type = list(string)
  default = []

  validation {
    condition = alltrue([for a in var.s3_read_arn : a != "*"])
    error_message = "Wildcard * is not allowed. Please, specify the exact bucket/object ARNs !!"
  }
}

variable "s3_write_arn" {
  description = "This is to validate the S3 bucket/object ARNs this role can write from"
  type = list(string)
  default = []

  validation {
    condition = alltrue([for a in var.s3_write_arn : a != "*"])
    error_message = "Wildcard * is not allowed. Please, specify the exact bucket/object ARNs !!"
  }
}

variable "secrets_read_arn" {
  description = "Secrets Manager secret ARNs this role may read"
  type = list(string)
  default = []

  validation {
    condition = alltrue([for a in var.secrets_read_arn : a != "*"])
    error_message = "Wildcard * is not allowed. Please, specify the exact secret ARNs !!"
  }
}