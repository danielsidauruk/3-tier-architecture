
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
    Name        = "${var.application_name}-vpce"
    application = var.application_name
  }
}
