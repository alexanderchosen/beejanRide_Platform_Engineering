#
variable "name_prefix" {
  type = string
}

variable "purpose" {
  type= string
}

variable "data_classification" {
  type = string
  default = "internal"

  validation {
    condition = contains(["public", "internal", "sensitive"], var.data_classification)
    error_message = "data_classification must be public, internal, or sensitive."
  }
}

variable "lifecycle_days" {
  type = number
  default = null
}

variable "enable_versioning" {
  type = bool
  default = true
}