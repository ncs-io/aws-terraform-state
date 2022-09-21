output "state_bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "state_bucket_arn" {
  value = aws_s3_bucket.state.arn
}

output "state_kms_arn" {
  value = one(aws_kms_key.encryption_key[*].arn)
}

output "state_kms_id" {
  value = one(aws_kms_key.encryption_key[*].key_id)
}

output "state_table_name" {
  value = aws_dynamodb_table.terraform_lock.name
}

output "state_table_arn" {
  value = aws_dynamodb_table.terraform_lock.arn
}
