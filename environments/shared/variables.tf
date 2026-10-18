variable "domain_name" {
  description = "Root domain the hosted zone serves."
  type        = string
  default     = "motifpath.com"
}

variable "dmarc_record" {
  description = "Value of the _dmarc TXT record, unquoted. Carried over from the previous DNS host with its rua address pointed at a MotifPath mailbox."
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly spend, in US dollars, the budget alerts are measured against."
  type        = number
  default     = 80
}

variable "budget_alert_emails" {
  description = "Addresses that receive budget alerts."
  type        = list(string)
}
