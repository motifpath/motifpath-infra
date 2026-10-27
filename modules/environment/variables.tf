variable "environment" {
  description = "Which environment this is."
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "environment must be staging or production."
  }
}

variable "domain_name" {
  description = "Root domain; production uses its first-level names, staging the ones under staging."
  type        = string
}

variable "zone_id" {
  description = "Hosted zone of the root domain."
  type        = string
}

variable "vm_public_ip" {
  description = "Elastic IP of the shared VM, the target of the API hostnames."
  type        = string
}

variable "vm_instance_arn" {
  description = "ARN of the shared VM, the only target the deploy role may send commands to."
  type        = string
}

variable "instance_role_name" {
  description = "Role of the shared VM; this environment attaches its own policy to it."
  type        = string
}

variable "ecr_registry" {
  description = "Registry host the service images are pulled from."
  type        = string
}

variable "ecr_repository_arns" {
  description = "Service image repositories by name."
  type        = map(string)
}

variable "core_repository" {
  description = "GitHub owner/name of the backend repository."
  type        = string
  default     = "motifpath/motifpath-core"
}

variable "database_address" {
  description = "Hostname of the shared Postgres instance."
  type        = string
}

variable "database_port" {
  description = "Port of the shared Postgres instance."
  type        = number
}

variable "mail_allowed_recipients" {
  description = "Address patterns every recipient of this environment's email must match, or null for any recipient. Every environment but production must set it, so only production can mail real users."
  type        = list(string)
  default     = null

  validation {
    condition     = var.environment == "production" || var.mail_allowed_recipients != null
    error_message = "Only production may send to any recipient; set mail_allowed_recipients."
  }
}

variable "concierge_email" {
  description = "Address the weekly student summary goes to, or null to send none. Outside production it must match mail_allowed_recipients, or SES refuses it."
  type        = string
  default     = null
}
