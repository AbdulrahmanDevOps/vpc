output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.nat[*].id
}

output "nat_eip_ids" {
  description = "List of Elastic IP IDs"
  value       = aws_eip.nat[*].id
}

output "nat_eip_public_ips" {
  description = "List of Elastic IP public addresses"
  value       = aws_eip.nat[*].public_ip
}