
resource "aws_eip" "nat" {

  for_each = local.private_subnets

  tags = {
    Name        = "${var.application_name}-eip"
    application = var.application_name
  }
}

resource "aws_nat_gateway" "nat" {

  for_each = local.private_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  depends_on = [
    aws_internet_gateway.main,
  ]

  tags = {
    Name        = "${var.application_name}-nat"
    application = var.application_name
  }

}
