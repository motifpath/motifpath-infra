variable "name" {
  description = "Name of the budget."
  type        = string
}

variable "monthly_limit_usd" {
  description = "Monthly spend, in US dollars, the alerts are measured against."
  type        = number
}

variable "alert_emails" {
  description = "Addresses that receive the budget alerts."
  type        = list(string)
}

variable "alerts" {
  description = "Alerts keyed by name: a percentage of the limit, on ACTUAL or FORECASTED spend."
  type = map(object({
    percent = number
    type    = string
  }))
  default = {
    actual-80      = { percent = 80, type = "ACTUAL" }
    forecasted-100 = { percent = 100, type = "FORECASTED" }
  }
}
