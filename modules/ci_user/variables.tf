variable "name" {
  description = "Name of the IAM user and its inline policy."
  type        = string
}

variable "policy_json" {
  description = "What the user may do, as a JSON policy document."
  type        = string
}
