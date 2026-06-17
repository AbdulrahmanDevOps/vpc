output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.private[*].id
}

output "private_route_tables_by_az" {
  value = {
    for i, az in slice(var.availability_zones, 0, length(aws_route_table.private)) :
    az => aws_route_table.private[i].id
  }
}
