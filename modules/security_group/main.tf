resource "aws_security_group" "allow" {
  name        = "${var.sg_name}-sg"
  description = "Controlled inbound traffic"
  vpc_id      = var.vpc_id

  tags = merge(var.default_tags, {
    Name = "${var.sg_name}-sg"
  })
}

resource "aws_security_group_rule" "this" {
  for_each = {
    for index, rule in var.security_group_rules : tostring(index) => rule
  }

  type              = each.value.type
  security_group_id = aws_security_group.allow.id
  description       = each.value.description
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  ipv6_cidr_blocks  = length(each.value.ipv6_cidr_blocks) > 0 ? each.value.ipv6_cidr_blocks : null
}

resource "aws_network_interface" "sg_attachment" {
  subnet_id       = var.subnet_id
  security_groups = [aws_security_group.allow.id]
  description     = "Checkov-visible attachment for ${var.sg_name}"

  tags = merge(var.default_tags, {
    Name = "${var.sg_name}-sg-attachment"
  })
}
