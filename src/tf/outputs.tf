output "backend_bucket_name" {
  description = "S3 bucket name for OpenTofu state storage."
  value       = aws_s3_bucket.tfstate_state.bucket
}

output "backend_table_name" {
  description = "DynamoDB table name for state locking."
  value       = aws_dynamodb_table.tflock_state.name
}
