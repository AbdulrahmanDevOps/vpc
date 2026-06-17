#########################################
# Locals (AZ Validation)
#########################################

locals {
  selected_azs = distinct([for subnet in var.subnets : subnet.az])
}

############################################
# Create VPC
############################################
module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.name
  availability_zones   = local.selected_azs
  subnets              = var.subnets
  nacl_name            = var.name
  security_group_rules = var.security_group_rules
  default_tags         = var.default_tags
}

############################################
# Create Internet Gateway
############################################
module "internet_gateway" {
  source   = "./modules/internet_gateway"
  vpc_id   = module.vpc.vpc_id
  igw_name = var.name
}

############################################
# Create NAT Gateway
############################################
module "nat_gateway" {
  source             = "./modules/nat_gateway"
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  public_subnet_ids  = module.vpc.public_subnet_ids
  nat_name           = var.name
  internet_gateway   = module.internet_gateway.igw_id
}

############################################
# Create Route Tables
############################################
module "route_table" {
  source              = "./modules/route_table"
  vpc_id              = module.vpc.vpc_id
  internet_gateway_id = module.internet_gateway.igw_id
  enable_nat_gateway  = var.enable_nat_gateway
  single_nat_gateway  = var.single_nat_gateway
  nat_gateway_ids     = module.nat_gateway.nat_gateway_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  availability_zones  = local.selected_azs
  rt_name             = var.name
}

############################################
#Create Security Group
############################################
module "security_group" {
  source               = "./modules/security_group"
  vpc_id               = module.vpc.vpc_id
  sg_name              = var.name
  security_group_rules = var.security_group_rules
  default_tags         = var.default_tags
  subnet_id            = module.vpc.public_subnet_ids[0]
}
