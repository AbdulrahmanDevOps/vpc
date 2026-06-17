variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name prefix for VPC resources"
  type        = string
}
variable "availability_zones" {
  description = "Availability zones selected by the root module."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Subnets to create in the VPC."
  type = list(object({
    name = string
    cidr = string
    type = string
    az   = string
  }))
  default = []
}

variable "nacl_name" {
  description = "Name prefix for the Network ACL."
  type        = string
}

variable "security_group_rules" {
  description = "Security group rules used to derive Network ACL rules."
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
  description = "Tags to apply to VPC module resources."
  type        = map(string)
  default     = {}
}
