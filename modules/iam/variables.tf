variable "name_prefix" {
  type = string
}

variable "role-use" {
  type = string
}

variable "trusted_service" {
  type = string

  validation {
    condition = contains(["ecs-tasks", "ec2"], var.trusted_service)
    error_message = "trusted_service must be either an ecs-tasks or ec2."
  }
}


# so, i had to encourage least-privilege access by restricting wildcard access to the resources ("*")

variable "s3_read_arn" {
  type = list(string)
  default = []

  validation {
    condition = alltrue([for a in var.s3_read_arn : a != "*"])
    error_message = "Wildcard * is not allowed. Please, specify the exact bucket/object ARNs !!"
  }
}

variable "s3_write_arn" {
  type = list(string)
  default = []

  validation {
    condition = alltrue([for a in var.s3_write_arn : a != "*"])
    error_message = "Wildcard * is not allowed. Please, specify the exact bucket/object ARNs !!"
  }
}

variable "secrets_read_arn" {
  type = list(string)
  default = []

  validation {
    condition = alltrue([for a in var.secrets_read_arn : a != "*"])
    error_message = "Wildcard * is not allowed. Please, specify the exact secret ARNs !!"
  }
}

variable "athena_workgroup_arns" {
  type = list(string)
  default = []
  validation {
    condition = alltrue([for a in var.athena_workgroup_arns : a != "*"])
    error_message = "Wildcard * is not allowed. Specify exact workgroup ARNs."
  }
}

variable "glue_database_arns" {
  type = list(string)
  default = []
  validation {
    condition = alltrue([for a in var.glue_database_arns : a != "*"])
    error_message = "Wildcard * is not allowed. Specify exact Glue database/table ARNs."
  }
}