provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      environment = "shared"
      project     = "motifpath"
      managed-by  = "terraform"
    }
  }
}
