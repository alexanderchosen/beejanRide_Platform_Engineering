output "vpc_id" {
  description = "This is to get the ID of the VPC"
  value = aws_vpc.create_vpc.id
}

output "vpc_cidr_block" {
  description = "This is to get the CIDR block of the VPC"
  value = aws_vpc.create_vpc.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "default_security_group_id" {
  value = aws_default_security_group.default_sg.id
}