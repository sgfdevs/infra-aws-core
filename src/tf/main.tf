resource "aws_s3_bucket" "tfstate_global" {
  bucket = "sgfdevs-global-tfstate"

  tags = merge(
    var.tags,
    {
      Name        = "sgfdevs-global-tfstate"
      Environment = "global"
      ManagedBy   = "OpenTofu"
    }
  )
}

resource "aws_s3_bucket_versioning" "tfstate_global" {
  bucket = aws_s3_bucket.tfstate_global.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_global" {
  bucket = aws_s3_bucket.tfstate_global.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_global" {
  bucket = aws_s3_bucket.tfstate_global.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate_global" {
  bucket = aws_s3_bucket.tfstate_global.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_dynamodb_table" "tflock_global" {
  name         = "sgfdevs-global-tflock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.tags,
    {
      Name        = "sgfdevs-global-tflock"
      Environment = "global"
      ManagedBy   = "OpenTofu"
    }
  )
}
