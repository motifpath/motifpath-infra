variable "repository_names" {
  description = "Names of the image repositories to create."
  type        = set(string)
}

variable "images_to_keep" {
  description = "Images kept per repository; older ones expire."
  type        = number
  default     = 50
}
