moved {
  from = aws_s3_bucket.tfstate["state"]
  to   = aws_s3_bucket.tfstate_state
}

moved {
  from = aws_s3_bucket_versioning.tfstate["state"]
  to   = aws_s3_bucket_versioning.tfstate_state
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.tfstate["state"]
  to   = aws_s3_bucket_server_side_encryption_configuration.tfstate_state
}

moved {
  from = aws_s3_bucket_public_access_block.tfstate["state"]
  to   = aws_s3_bucket_public_access_block.tfstate_state
}

moved {
  from = aws_s3_bucket_ownership_controls.tfstate["state"]
  to   = aws_s3_bucket_ownership_controls.tfstate_state
}

moved {
  from = aws_dynamodb_table.tflock["state"]
  to   = aws_dynamodb_table.tflock_state
}

locals {
  backends = {
    global = {
      bucket_name = "sgfdevs-global-tfstate"
      table_name  = "sgfdevs-global-tflock"
      environment = "global"
    }
    prod = {
      bucket_name = "sgfdevs-environment-prod-tfstate"
      table_name  = "sgfdevs-environment-prod-tflock"
      environment = "prod"
    }
  }
}

resource "aws_s3_bucket" "tfstate" {
  for_each = local.backends
  region   = var.aws_region

  bucket = each.value.bucket_name

  tags = merge(
    var.tags,
    {
      "Name"        = each.value.bucket_name
      "Environment" = each.value.environment
      "ManagedBy"   = "OpenTofu"
    }
  )
}

resource "aws_s3_bucket_versioning" "tfstate" {
  for_each = local.backends
  region   = var.aws_region

  bucket = aws_s3_bucket.tfstate[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  for_each = local.backends
  region   = var.aws_region

  bucket = aws_s3_bucket.tfstate[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  for_each = local.backends
  region   = var.aws_region

  bucket = aws_s3_bucket.tfstate[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "tfstate" {
  for_each = local.backends
  region   = var.aws_region

  bucket = aws_s3_bucket.tfstate[each.key].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_dynamodb_table" "tflock" {
  for_each = local.backends

  name         = each.value.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  region       = var.aws_region

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.tags,
    {
      "Name"        = each.value.table_name
      "Environment" = each.value.environment
      "ManagedBy"   = "OpenTofu"
    }
  )
}

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
