output "security_group_id" {
  value = aws_security_group.allow.id
}

output "security_group_rule_ids" {
  value = { for k, r in aws_security_group_rule.this : k => r.id }
}

output "network_interface_id" {
  value = aws_network_interface.sg_attachment.id
}
