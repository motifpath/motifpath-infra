variable "name" {
  description = "Name of the role."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  type        = string
}

variable "subjects" {
  description = "Token subjects allowed to assume the role, e.g. repo:org/repo:environment:production."
  type        = list(string)
}

variable "policy_json" {
  description = "What the role may do, as a JSON policy document."
  type        = string
}
