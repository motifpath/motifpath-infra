# The credentials core-domain uses for media. Containers cannot reach the
# instance role (the metadata service answers the host only), so each
# environment's service gets its own key, which can touch nothing but that
# environment's media bucket.
resource "aws_iam_user" "this" {
  name = var.name
}

resource "aws_iam_user_policy" "this" {
  name = var.name
  user = aws_iam_user.this.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "MediaObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${var.bucket_arn}/*"
      },
      {
        Sid      = "MediaBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = var.bucket_arn
      },
    ]
  })
}

# Rotate by replacing it: terraform apply -replace=<address of this key>,
# then redeploy so the service picks up the new one.
resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}
