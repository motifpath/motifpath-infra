output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_id" {
  description = "ID of the public subnet the VM runs in."
  value       = aws_subnet.public.id
}

output "private_subnet_ids" {
  description = "IDs of the route-less private subnets, one per availability zone."
  value       = [for subnet in aws_subnet.private : subnet.id]
}
