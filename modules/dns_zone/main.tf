resource "aws_route53_zone" "this" {
  name = var.domain_name

  lifecycle {
    # Deleting the zone changes its nameservers, which the registrar points
    # at by hand.
    prevent_destroy = true
  }
}
