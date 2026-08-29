# this is for the catalog db and the crawler role

resource "aws_glue_catalog_database" "create_cat_db" {
  name = replace("${var.name_prefix}_${var.purpose}", "-", "_")
}

resource "aws_iam_role" "crawler" {
  name = "${var.name_prefix}-${var.purpose}-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "crawler_s3" {
  name = "${var.name_prefix}-${var.purpose}-crawler-s3"
  role = aws_iam_role.crawler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject", "s3:ListBucket"]
      Resource = [var.source_bucket_arn, "${var.source_bucket_arn}/${var.source_prefix}*"]
    }]
  })
}

resource "aws_iam_role_policy" "crawler_glue" {
  name = "${var.name_prefix}-${var.purpose}-crawler-glue"
  role = aws_iam_role.crawler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "glue:GetDatabase", "glue:GetTable", "glue:GetTables",
        "glue:CreateTable", "glue:UpdateTable",
        "glue:BatchCreatePartition", "glue:GetPartitions"
      ]
      Resource = [
        "arn:aws:glue:*:*:catalog",
        aws_glue_catalog_database.create_cat_db.arn,
        "${replace(aws_glue_catalog_database.create_cat_db.arn, ":database/", ":table/")}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "crawler_logs" {
  name = "${var.name_prefix}-${var.purpose}-crawler-logs"
  role = aws_iam_role.crawler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "arn:aws:logs:*:*:log-group:/aws-glue/*"
    }]
  })
}

resource "aws_glue_crawler" "my_glue" {
  name = "${var.name_prefix}-${var.purpose}-crawler"
  role = aws_iam_role.crawler.arn
  database_name = aws_glue_catalog_database.create_cat_db.name
  schedule = var.crawler_schedule != "" ? "cron(${var.crawler_schedule})" : null

  s3_target {
    path = "s3://${var.source_bucket_name}/${var.source_prefix}"
  }
}

module "athena_results_bucket" {
  source  = "../s3"
  name_prefix = var.name_prefix
  purpose = "${var.purpose}-athena-results"
  data_classification = "internal"
  lifecycle_days = 30
}

resource "aws_athena_workgroup" "workgroup" {
  name = "${var.name_prefix}-${var.purpose}-wg"

  configuration {
    enforce_workgroup_configuration = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${module.athena_results_bucket.bucket_name}/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}