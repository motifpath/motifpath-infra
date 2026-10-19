variable "zone_id" {
  description = "Hosted zone the records are created in."
  type        = string
}

variable "records" {
  description = "Records keyed by a stable name. `name` is the full record name; TXT values are given unquoted."
  type = map(object({
    name   = string
    type   = string
    values = list(string)
  }))
}

variable "ttl" {
  description = "TTL of every record, in seconds."
  type        = number
  default     = 300
}
