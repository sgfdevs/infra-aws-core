output "backend_bucket_names" {
  description = "S3 bucket names for OpenTofu state by environment key."
  value       = { for key, bucket in aws_s3_bucket.tfstate : key => bucket.bucket }
}

output "backend_table_names" {
  description = "DynamoDB table names for state locking by environment key."
  value       = { for key, table in aws_dynamodb_table.tflock : key => table.name }
}
