variable "name" {
  description = "Name of the inline policy, unique within the role."
  type        = string
}

variable "role_name" {
  description = "Name of the existing role the policy is attached to."
  type        = string
}

variable "policy_json" {
  description = "The policy document, as JSON."
  type        = string
}
