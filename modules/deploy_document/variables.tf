variable "name" {
  description = "Name of the SSM document."
  type        = string
}

variable "environment" {
  description = "Environment the document deploys; fixed, not a parameter."
  type        = string
}

variable "repository" {
  description = "GitHub owner/name the deploy files are fetched from. Must be public: the VM fetches without credentials."
  type        = string
}

variable "allowed_branches" {
  description = "Branches a commit must be on to be deployed to this environment, checked in order."
  type        = list(string)
}

variable "timeout_seconds" {
  description = "How long a deploy may run before it is stopped."
  type        = number
  default     = 1800
}
