variable "names" {
  description = "Names of the CloudWatch log groups to create."
  type        = set(string)
}

variable "retention_in_days" {
  description = "How long log events are kept."
  type        = number
  default     = 30
}
