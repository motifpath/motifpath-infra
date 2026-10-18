variable "path" {
  description = "Path the parameters are created under, without a trailing slash."
  type        = string
}

variable "string_parameters" {
  description = "Plain parameters: name => value."
  type        = map(string)
  default     = {}
}

variable "secure_parameters" {
  description = "Encrypted parameters whose values Terraform knows: name => value."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "manual_parameters" {
  description = "Names of encrypted parameters whose values are set by hand outside Terraform."
  type        = set(string)
  default     = []
}
