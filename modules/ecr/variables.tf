variable "repository_names" {
  description = "Names of the image repositories to create."
  type        = set(string)
}

variable "protected_tag_prefix" {
  description = "Tag prefix the production deploy adds to the images it runs; such images expire only among themselves."
  type        = string
  default     = "production-"
}

variable "protected_images_to_keep" {
  description = "Images with the protected tag prefix kept per repository."
  type        = number
  default     = 20
}

variable "images_to_keep" {
  description = "Images kept per repository; older ones expire."
  type        = number
  default     = 50
}
