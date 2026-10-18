output "zone_id" {
  description = "ID of the hosted zone."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Nameservers to set at the domain registrar."
  value       = aws_route53_zone.this.name_servers
}
