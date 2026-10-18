provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      environment = "production"
      project     = "motifpath"
      managed-by  = "terraform"
    }
  }
}
