variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
}

variable "single_nat_gateway" {
  description = "Create only one NAT Gateway"
  type        = bool
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "nat_name" {
  type = string
}

variable "internet_gateway" {
  type = any
}
