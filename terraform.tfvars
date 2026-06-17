aws_region = "us-east-1"

name = "vpc"

vpc_cidr = "10.0.0.0/16"

subnets = [
  {
    name = "public-subnet-a"
    cidr = "10.0.1.0/24"
    type = "public"
    az   = "us-east-1a"
  },
  {
    name = "public-subnet-b"
    cidr = "10.0.2.0/24"
    type = "public"
    az   = "us-east-1b"
  },
  {
    name = "private-subnet-a"
    cidr = "10.0.11.0/24"
    type = "private"
    az   = "us-east-1a"
  },
  {
    name = "private-subnet-b"
    cidr = "10.0.12.0/24"
    type = "private"
    az   = "us-east-1b"
  }
]

security_group_rules = [
  {
    type             = "ingress"
    protocol         = "tcp"
    from_port        = 22
    to_port          = 22
    cidr_blocks      = ["103.187.194.226/32"]
    ipv6_cidr_blocks = []
    description      = "allow-ssh"
  },
  {
    type             = "ingress"
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    description      = "allow-http"
  },
  {
    type             = "egress"
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    description      = "allow-all-egress"
  }
]

enable_nat_gateway = true

single_nat_gateway = false

default_tags = {
  ManagedBy   = "MyTeam"
  Environment = "Dev"
  Project     = "trim-cistern-492506-c4"
}

