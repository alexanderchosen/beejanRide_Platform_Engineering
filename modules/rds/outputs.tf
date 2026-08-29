output "db_endpoint" {
  value = aws_db_instance.my_db.endpoint
}

output "db_port" {
  value = aws_db_instance.my_db.port
}

output "credentials_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "security_group_id" {
  value = aws_security_group.sg_group.id
}