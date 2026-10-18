variable "name" {
  description = "Identifier of the instance and name prefix of its subnet and security groups."
  type        = string
}

variable "vpc_id" {
  description = "VPC the instance runs in."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets in at least two availability zones."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on 5432, keyed by a stable name."
  type        = map(string)
}

variable "engine_version" {
  description = "Postgres major version; minor upgrades apply automatically."
  type        = string
  default     = "16"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage_gb" {
  description = "Initial storage."
  type        = number
  default     = 20
}

variable "max_allocated_storage_gb" {
  description = "Ceiling storage autoscaling may grow to."
  type        = number
  default     = 50
}

variable "master_username" {
  description = "Administrative user, used only to create each environment's database and user."
  type        = string
  default     = "motifpath_admin"
}

variable "backup_retention_days" {
  description = "Days automated backups are kept."
  type        = number
  default     = 7
}
