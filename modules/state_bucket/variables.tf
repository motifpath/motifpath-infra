variable "bucket_name" {
  description = "Globally unique name of the bucket that holds every Terraform state file."
  type        = string
}

variable "noncurrent_version_retention_days" {
  description = "Days a superseded state version is kept before it is deleted."
  type        = number
  default     = 90
}
