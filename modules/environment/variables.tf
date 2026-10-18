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

variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider."
  type        = string
}

variable "core_repository" {
  description = "GitHub owner/name of the backend repository."
  type        = string
  default     = "motifpath/motifpath-core"
}

variable "web_repository" {
  description = "GitHub owner/name of the SPA repository."
  type        = string
  default     = "motifpath/motifpath-web"
}

variable "database_address" {
  description = "Hostname of the shared Postgres instance."
  type        = string
}

variable "database_port" {
  description = "Port of the shared Postgres instance."
  type        = number
}
