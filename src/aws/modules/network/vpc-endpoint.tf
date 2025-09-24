
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.primary_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

  tags = {
    Name        = "vpce"
    application = var.application_name
  }
}

resource "aws_security_group" "vpc_endpoint" {
  name        = "vpce-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [var.security_group_backend_id]
    description     = "Allow backend to access Secrets Manager VPC endpoint"
  }

  tags = {
    Name        = "vpce-sg"
    application = var.application_name
  }
}
