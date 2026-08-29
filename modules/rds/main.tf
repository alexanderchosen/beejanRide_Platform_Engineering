locals {
  db_name = "${var.name_prefix}-${var.purpose}"
  db_port = 5432
  instance_class = { small = "db.t3.micro", medium = "db.t3.small", large = "db.t3.medium" }[var.size_tier]
}

resource "random_password" "master_pw" {
  length  = 20
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${local.db_name}-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_cred_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin_user"
    password = random_password.master_pw.result
  })
}

resource "aws_db_subnet_group" "subnet_grp" {
  name = "${local.db_name}-sub-grp"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "sg_group" {
  name_prefix = "${local.db_name}-sg-"
  vpc_id = var.vpc_id

  ingress {
    from_port = local.db_port
    to_port = local.db_port
    protocol = "tcp"
    security_groups = [var.app_security_group_id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# when i tried to delete my database after creation using terraform destroy, i got an error because i didnt set skip_final_snapshot = true
resource "aws_db_instance" "my_db" {
  identifier = local.db_name
  engine = var.engine
  instance_class = local.instance_class
  allocated_storage = var.allocated_storage
  db_subnet_group_name = aws_db_subnet_group.subnet_grp.name
  vpc_security_group_ids = [aws_security_group.sg_group.id]
  username = jsondecode(aws_secretsmanager_secret_version.db_cred_version.secret_string)["username"]
  password = random_password.master_pw.result
  publicly_accessible = false
  multi_az = var.multi_az
  backup_retention_period = var.backup_retention_days
  deletion_protection = var.deletion_protection
  engine_version = var.engine_version
  skip_final_snapshot = true

  tags = {
    Name = local.db_name
  }
}

