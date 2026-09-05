# i first need to define a name prefix variable
variable "name_prefix"{
    type = string
}

# next,i have to set the cidr notation for the vpc
variable "vpc_cidr"{
    description = "This refers to the classless inter-domain routing for the VPCs created"
    type = string
    default = "10.0.0.0/16"
}

# because i am using a free tier account, i want to limit multiple AZs to a max of 3
variable "az_count" {
  description = "This is to set the count for the availability zones"
  type = number
  default = 2

  validation {
    condition = var.az_count >= 1 && var.az_count <= 3
    error_message = "The az_count must be within the range of 1 to 3"
  }
}

# since nat gateway are not needed in public subnets, I set the default to false so that it is strictly enabled for only private subnets
variable "nat_gateway_enable" {
    description = "This is used to know if the NAT gateway needed for only private subnets is needed or not"
    type = bool
    default = false
}

