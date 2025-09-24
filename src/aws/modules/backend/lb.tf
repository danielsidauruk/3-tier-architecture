
resource "aws_lb" "backend" {
  name               = "backend-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_lb_sg.id]
  subnets            = var.private_subnet_ids

  tags = {
    Name        = "lb"
    application = var.application_name
  }
}

resource "aws_lb_target_group" "backend" {
  name     = "be-http-tg"
  port     = var.backend_app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "be-http-tg"
    application = var.application_name
  }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = var.backend_app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
