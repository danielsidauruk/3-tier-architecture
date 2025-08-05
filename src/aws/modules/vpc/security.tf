
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.application_name}-vpce-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.application_name}-vpce-sg"
    application = var.application_name
  }
}

resource "aws_security_group_rule" "backend_to_vpce" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoint.id
  source_security_group_id = var.security_group_backend_id
  description              = "Allow backend to access Secrets Manager VPC endpoint"
}
