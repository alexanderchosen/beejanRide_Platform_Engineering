locals {
  trusted_principal = var.trusted_service == "ecs-tasks" ? "ecs-tasks.amazonaws.com" : "ec2.amazonaws.com"
  base_name = "${var.name_prefix}-${var.role-use}"
}

resource "aws_iam_role" "create_iam_role" {
  name = "${local.base_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = local.trusted_principal }
      Action = "sts:AssumeRole"
    }]
  })
}

# the count value here is used to check if there is an arn provided or not

resource "aws_iam_role_policy" "s3_read_policy" {
  count = length(var.s3_read_arn) > 0 ? 1 : 0
  name = "${local.base_name}-s3-read"
  role = aws_iam_role.create_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = var.s3_read_arn
    }]
  })
}

resource "aws_iam_role_policy" "s3_write" {
  count = length(var.s3_write_arn) > 0 ? 1 : 0
  name = "${local.base_name}-s3-write"
  role = aws_iam_role.create_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:PutObject", "s3:DeleteObject"]
      Resource = var.s3_write_arn
    }]
  })
}

resource "aws_iam_role_policy" "secrets_read" {
  count = length(var.secrets_read_arn) > 0 ? 1 : 0
  name = "${local.base_name}-secrets-read"
  role = aws_iam_role.create_iam_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = var.secrets_read_arn
    }]
  })
}

# because the EC2 service needs an instance profile to attach a role to an instance
resource "aws_iam_instance_profile" "create_instance_profile" {
  count = var.trusted_service == "ec2" ? 1 : 0
  name = "${local.base_name}-instance-profile"
  role = aws_iam_role.create_iam_role.name
}