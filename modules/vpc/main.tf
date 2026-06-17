data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  flow_log_group_name        = "/aws/vpc/${var.vpc_name}-flow-logs"
  flow_log_group_arn_pattern = "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.flow_log_group_name}*"

  public_subnet_indexes  = [for index, subnet in var.subnets : index if subnet.type == "public"]
  private_subnet_indexes = [for index, subnet in var.subnets : index if subnet.type == "private"]

  nacl_rule_entries = flatten([
    for rule_index, rule in var.security_group_rules : concat([
      for cidr_index, cidr_block in rule.cidr_blocks : {
        key             = "${rule.type}-${rule_index}-ipv4-${cidr_index}"
        type            = rule.type
        protocol        = rule.protocol
        from_port       = rule.from_port
        to_port         = rule.to_port
        cidr_block      = cidr_block
        ipv6_cidr_block = null
      }
      ], [
      for cidr_index, cidr_block in rule.ipv6_cidr_blocks : {
        key             = "${rule.type}-${rule_index}-ipv6-${cidr_index}"
        type            = rule.type
        protocol        = rule.protocol
        from_port       = rule.from_port
        to_port         = rule.to_port
        cidr_block      = null
        ipv6_cidr_block = cidr_block
      }
    ])
  ])

  nacl_rules = {
    for index, rule in local.nacl_rule_entries :
    rule.key => merge(rule, {
      rule_number = 100 + (index * 10)
    })
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.vpc_name}-vpc"
  }
}

resource "aws_subnet" "this" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
  }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = {
    Name = each.value.name
    AZ   = each.value.az
    Type = each.value.type
  }
}

resource "aws_network_acl" "this" {
  vpc_id = aws_vpc.main.id
  subnet_ids = [
    aws_subnet.this["public-subnet-a"].id,
    aws_subnet.this["public-subnet-b"].id,
    aws_subnet.this["private-subnet-a"].id,
    aws_subnet.this["private-subnet-b"].id
  ]

  tags = merge(var.default_tags, {
    Name = "${var.nacl_name}-nacl"
  })
}

resource "aws_network_acl_rule" "this" {
  for_each = local.nacl_rules

  network_acl_id  = aws_network_acl.this.id
  rule_number     = each.value.rule_number
  egress          = each.value.type == "egress"
  protocol        = lookup({ tcp = "6", udp = "17", icmp = "1" }, lower(each.value.protocol), each.value.protocol)
  rule_action     = "allow"
  cidr_block      = each.value.cidr_block
  ipv6_cidr_block = each.value.ipv6_cidr_block
  from_port       = each.value.from_port
  to_port         = each.value.to_port
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress = []
  egress  = []

  tags = {
    Name = "${var.vpc_name}-default-sg"
  }
}

resource "aws_kms_key" "flow_logs" {
  description             = "KMS key for VPC Flow Logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIamUserPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsUseOfKey"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.region}.amazonaws.com"
        }
        Action = [
          "kms:Decrypt*",
          "kms:Describe*",
          "kms:Encrypt*",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = local.flow_log_group_arn_pattern
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.vpc_name}-flowlogs-kms"
  }
}

resource "aws_kms_alias" "flow_logs" {
  name          = "alias/${var.vpc_name}-flowlogs"
  target_key_id = aws_kms_key.flow_logs.key_id
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = local.flow_log_group_name
  retention_in_days = 365
  kms_key_id        = aws_kms_key.flow_logs.arn

  tags = {
    Name = "${var.vpc_name}-flow-logs"
  }
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.vpc_name}-flowlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.vpc_name}-flowlogs-role"
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "${var.vpc_name}-flowlogs-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_cloudwatch_log_group.vpc_flow_logs.arn,
          "${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn         = aws_iam_role.flow_logs.arn

  tags = {
    Name = "${var.vpc_name}-flow-log"
  }
}
