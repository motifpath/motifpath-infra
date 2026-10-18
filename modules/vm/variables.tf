variable "name" {
  description = "Name of the instance and of its security group, role and profile."
  type        = string
}

variable "vpc_id" {
  description = "VPC the instance runs in."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet the instance runs in."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type. Must be arm64 (Graviton): the images are built for linux/arm64."
  type        = string
  default     = "t4g.medium"
}

variable "ami_ssm_parameter" {
  description = "Public SSM parameter that resolves to the AMI to boot from."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

variable "root_volume_size_gb" {
  description = "Size of the root volume, which also holds images and broker data."
  type        = number
  default     = 40
}

variable "swap_size_mb" {
  description = "Size of the swap file created on first boot."
  type        = number
  default     = 2048
}

variable "compose_version" {
  description = "Docker Compose plugin version installed on first boot, without the leading v."
  type        = string
  default     = "2.40.3"
}
