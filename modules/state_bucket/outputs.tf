output "bucket_name" {
  description = "Name of the state bucket, for backend blocks."
  value       = aws_s3_bucket.this.id
}
