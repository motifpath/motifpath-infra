variable "domain" {
  description = "Domain the environment sends email from, such as mail.example.com. It must sit in the hosted zone given by zone_id."
  type        = string
}

variable "zone_id" {
  description = "Hosted zone the DKIM and MAIL FROM records are created in."
  type        = string
}

variable "user_name" {
  description = "Name of the IAM user, and its policy, that may send from the domain."
  type        = string
}

variable "allowed_recipients" {
  description = "Address patterns (SES StringLike, such as *@example.com) that every recipient must match. Null allows any recipient."
  type        = list(string)
  default     = null

  validation {
    condition     = var.allowed_recipients == null ? true : length(var.allowed_recipients) > 0
    error_message = "allowed_recipients must be null or list at least one pattern; an empty list would block all mail."
  }
}
