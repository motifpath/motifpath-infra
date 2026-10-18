data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_ecr_repository" "this" {
  for_each = var.repository_names

  name = each.key
  # Images are tagged with the commit they were built from; a tag must never
  # be pointed at different contents later.
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = aws_ecr_repository.this

  repository = each.value.name
  # An image matched by an earlier rule is never expired by a later one, so
  # images carrying the protected prefix are counted only among themselves:
  # however many release candidates are built, what production ran recently
  # stays pullable for redeploys and rollbacks.
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the most recent images that ran in production."
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = [var.protected_tag_prefix]
          countType     = "imageCountMoreThan"
          countNumber   = var.protected_images_to_keep
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep the most recent of every other image."
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.images_to_keep
        }
        action = { type = "expire" }
      },
    ]
  })
}
