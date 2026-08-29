variable "name_prefix" {
  type = string
}

variable "purpose" {
  type = string
}

variable "source_bucket_arn" {
  type = string
}

variable "source_bucket_name" {
  type = string
}

variable "source_prefix" {
  type = string
  default = ""
}

variable "crawler_schedule" {
  type = string
  default = ""
}