provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      environment = "shared"
      project     = "motifpath"
      managed-by  = "terraform"
    }
  }
}
