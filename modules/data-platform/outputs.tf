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