
resource "aws_lb" "frontend" {
  name               = "${var.application_name}-frontend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.frontend_lb_sg.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "${var.application_name}-frontend-lb"
    application = var.application_name
  }
}

resource "aws_lb_target_group" "frontend" {
  name     = "${var.application_name}-fe-http-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.application_name}-fe-http-tg"
    application = var.application_name
  }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}
