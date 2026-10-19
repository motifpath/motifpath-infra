output "state_bucket" {
  description = "Bucket the backend blocks point at."
  value       = module.state_bucket.bucket_name
}
