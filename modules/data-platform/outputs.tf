output "glue_database_name" {
  value = aws_glue_catalog_database.create_cat_db.name
}

output "athena_workgroup_name" {
  value = aws_athena_workgroup.workgroup.name
}

output "crawler_name" {
  value = aws_glue_crawler.my_glue.name
}

output "results_bucket_name" {
  value = module.athena_results_bucket.bucket_name
}

output "glue_database_arn" {
  value = aws_glue_catalog_database.create_cat_db.arn
}

output "athena_workgroup_arn" {
  value = aws_athena_workgroup.workgroup.arn
}

output "results_bucket_arn" {
  value = module.athena_results_bucket.bucket_arn
}