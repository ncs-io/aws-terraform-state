locals {
  bucket_name = join("-", compact([var.project, "state-bucket", var.environment]))
  table_name  = join("-", compact([var.project, "state-lock-table", var.environment]))

  tags = merge({
    "managed-by" = "Terraform"
    "module"     = "aws-terraform-state"
  }, var.tags)
}

resource "aws_kms_key" "encryption_key" {
  count                   = var.use_kms ? 1 : 0
  description             = "This key is used to encrypt state bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = local.tags
}

#tfsec:ignore:aws-s3-enable-bucket-logging REASON: Should be done on CloudTrail level
resource "aws_s3_bucket" "state" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = local.tags
}

resource "aws_s3_bucket_acl" "state_bucket_acl" {
  bucket = aws_s3_bucket.state.bucket
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "all" {
  bucket = aws_s3_bucket.state.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.bucket
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kms" {
  count  = var.use_kms ? 1 : 0
  bucket = aws_s3_bucket.state.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.encryption_key[0].arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  count  = var.use_kms ? 0 : 1
  bucket = aws_s3_bucket.state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#tfsec:ignore:aws-dynamodb-enable-recovery REASON: Locks do not need recovery
resource "aws_dynamodb_table" "terraform_lock" {
  name           = local.table_name
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.use_kms ? aws_kms_key.encryption_key[0].arn : null
  }

  tags = merge({
    "Name" = "State Lock Table for ${var.project}"
  }, local.tags)
}
