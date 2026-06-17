# Elastic IP
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (
    var.single_nat_gateway ? 1 : length(var.public_subnet_ids)
  ) : 0

  domain = "vpc"

  tags = {
    Name = "${var.nat_name}-nat-eip-${count.index + 1}"
  }

  depends_on = [var.internet_gateway]
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway ? (
    var.single_nat_gateway ? 1 : length(var.public_subnet_ids)
  ) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = var.single_nat_gateway ? var.public_subnet_ids[0] : var.public_subnet_ids[count.index]

  tags = {
    Name = "${var.nat_name}-nat-${count.index + 1}"
  }

  depends_on = [aws_eip.nat]
}
