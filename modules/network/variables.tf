variable "name" {
  description = "Name prefix for the VPC and its subnets."
  type        = string
}

variable "cidr_block" {
  description = "IPv4 range of the VPC; subnets are /24 slices of it."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "At least two zones. The first hosts the public subnet; every zone gets a private subnet."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "A database subnet group needs at least two availability zones."
  }
}
