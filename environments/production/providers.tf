provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      environment = "production"
      project     = "motifpath"
      managed-by  = "terraform"
    }
  }
}

# CloudFront only accepts certificates issued in us-east-1; nothing else is
# created there.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      environment = "production"
      project     = "motifpath"
      managed-by  = "terraform"
    }
  }
}
