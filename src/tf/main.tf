resource "aws_s3_bucket" "tfstate_state" {
  region = var.aws_region
  bucket = "sgfdevs-infra-tf-state"

  tags = merge(
    var.tags,
    {
      Name        = "sgfdevs-infra-tf-state"
      Environment = "global"
      ManagedBy   = "OpenTofu"
    }
  )
}

resource "aws_s3_bucket_versioning" "tfstate_state" {
  region = var.aws_region
  bucket = aws_s3_bucket.tfstate_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate_state" {
  region = var.aws_region
  bucket = aws_s3_bucket.tfstate_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate_state" {
  region = var.aws_region
  bucket = aws_s3_bucket.tfstate_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate_state" {
  region = var.aws_region
  bucket = aws_s3_bucket.tfstate_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_dynamodb_table" "tflock_state" {
  region       = var.aws_region
  name         = "sgfdevs-infra-tflock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.tags,
    {
      Name        = "sgfdevs-infra-tflock"
      Environment = "global"
      ManagedBy   = "OpenTofu"
    }
  )
}
