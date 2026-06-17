variable "vpc_id" {
  type = string
}

variable "sg_name" {
  type = string
}

variable "security_group_rules" {
  description = "Security group rules to apply."
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
}

variable "default_tags" {
  description = "Tags to apply to the security group."
  type        = map(string)
  default     = {}
}

variable "subnet_id" {
  description = "Subnet ID for attaching the security group to a network interface."
  type        = string
}
