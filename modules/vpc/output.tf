output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_flow_log_group_name" {
  value = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for index in local.public_subnet_indexes : aws_subnet.this[var.subnets[index].name].id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for index in local.private_subnet_indexes : aws_subnet.this[var.subnets[index].name].id]
}

output "public_subnets_by_az" {
  description = "Public subnets mapped by AZ"
  value = {
    for index in local.public_subnet_indexes :
    var.subnets[index].az => aws_subnet.this[var.subnets[index].name].id
  }
}

output "private_subnets_by_az" {
  description = "Private subnets mapped by AZ"
  value = {
    for index in local.private_subnet_indexes :
    var.subnets[index].az => aws_subnet.this[var.subnets[index].name].id
  }
}

output "nacl_id" {
  description = "ID of the created Network ACL"
  value       = aws_network_acl.this.id
}

output "nacl_rule_ids" {
  description = "Map of generated Network ACL rule ids keyed by internal rule key"
  value       = { for k, r in aws_network_acl_rule.this : k => r.id }
}

output "availability_zones" {
  description = "List of available availability zones"
  value       = var.availability_zones
}
