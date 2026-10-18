provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      environment = "staging"
      project     = "motifpath"
      managed-by  = "terraform"
    }
  }
}
