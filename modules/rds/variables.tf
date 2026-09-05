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

variable "app_security_group_id" {
  type = string
}

variable "engine" {
  type = string
  default = "postgres"

  }

variable "engine_version" {
  type = string
  default = "18.3"
}

variable "size_tier" {
  type = string
  default = "small"

  validation {
    condition = contains(["small", "medium", "large"], var.size_tier)
    error_message = "size_tier must be SMALL, MEDIUM or LARGE."
  }
}

# The storage here is calculated in GB
variable "allocated_storage" {
  type = number
  default = 20
}

variable "multi_az" {
  type = bool
  default = false
}

variable "backup_retention_days" {
  type = number
  default = 1
}

variable "deletion_protection" {
  type = bool
  default = false
}