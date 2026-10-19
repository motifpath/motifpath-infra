variable "bucket_name" {
  description = "Globally unique name of the bucket."
  type        = string
}

variable "domain_name" {
  description = "Hostname the distribution serves; gets its own certificate and alias records."
  type        = string
}

variable "zone_id" {
  description = "Hosted zone for the certificate validation and alias records."
  type        = string
}

variable "single_page_app" {
  description = "Serve index.html at the root and for every missing path, for a client-routed app."
  type        = bool
  default     = false
}

variable "upload_allowed_origins" {
  description = "Origins allowed to upload into the bucket directly from a browser. Empty disables CORS."
  type        = list(string)
  default     = []
}

variable "price_class" {
  description = "CloudFront price class."
  type        = string
  default     = "PriceClass_All"
}

variable "cors_allow_any_origin" {
  description = "Let pages on any origin read the content with fetch or Web Audio, by answering CORS at CloudFront. For public assets only."
  type        = bool
  default     = false
}
