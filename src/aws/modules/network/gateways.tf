
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "igw"
    application = var.application_name
  }
}

resource "aws_eip" "nat" {
  tags = {
    Name        = "eip"
    application = var.application_name
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [
    aws_internet_gateway.main,
  ]

  tags = {
    Name        = "nat"
    application = var.application_name
  }
}
