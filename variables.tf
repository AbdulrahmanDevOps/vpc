variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "name" {
  description = "Name of VPC"
  type        = string

}

variable "default_tags" {
  description = "Map of default tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "AutoCloud"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  validation {
    condition     = tonumber(split("/", var.vpc_cidr)[1]) <= 24
    error_message = "VPC CIDR must be /24 or larger (example: /16, /20, /24). Smaller networks like /25 are not allowed."
  }
}

variable "subnets" {
  description = "Subnets to create in the VPC."
  type = list(object({
    name = string
    cidr = string
    type = string
    az   = string
  }))

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be provided."
  }

  validation {
    condition     = alltrue([for subnet in var.subnets : contains(["public", "private"], subnet.type)])
    error_message = "Each subnet type must be either public or private."
  }

  validation {
    condition     = length(var.subnets) == length(distinct([for subnet in var.subnets : subnet.name]))
    error_message = "Each subnet name must be unique."
  }

  validation {
    condition     = length(var.subnets) == 0 || length([for subnet in var.subnets : subnet if subnet.type == "public"]) > 0
    error_message = "At least one public subnet is required when subnets are provided."
  }
}

variable "security_group_rules" {
  description = "Security group rules. The same rules are also used to create Network ACL rules."
  type = list(object({
    type             = string
    protocol         = string
    from_port        = number
    to_port          = number
    cidr_blocks      = list(string)
    ipv6_cidr_blocks = list(string)
    description      = string
  }))
  default = []

  validation {
    condition     = alltrue([for rule in var.security_group_rules : contains(["ingress", "egress"], rule.type)])
    error_message = "Each security_group_rules item must have type set to ingress or egress."
  }

  validation {
    condition     = alltrue([for rule in var.security_group_rules : length(rule.cidr_blocks) + length(rule.ipv6_cidr_blocks) > 0])
    error_message = "Each security_group_rules item must include at least one IPv4 or IPv6 CIDR block."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
}

variable "single_nat_gateway" {
  description = "Use single NAT Gateway for all private subnets"
  type        = bool
}
