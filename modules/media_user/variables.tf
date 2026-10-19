variable "name" {
  description = "Name of the IAM user and its policy."
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the only bucket the user may read and write."
  type        = string
}
