# --- Data Sources ---
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Security ---
resource "aws_security_group" "frontend_lb_sg" {
  name        = "frontend-lb-sg"
  description = "Security group for frontend load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow http traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow https traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "frontend" {
  name        = "frontend-sg"
  description = "Allow SSH and web traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_lb_sg.id]
    description     = "Allow app traffic from load balancer"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_lb_sg.id]
    description     = "Allow app traffic from load balancer"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Load Balancer ---
resource "aws_lb" "frontend" {
  name               = "frontend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.frontend_lb_sg.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "frontend" {
  name     = "fe-http-tg"
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

# --- Launch Template & Autoscaling ---
resource "aws_launch_template" "frontend" {
  name_prefix            = "frontend-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.frontend.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    REPO_URL        = var.repo_url
    REPO_CLONE_DIR  = "/tmp/frontend-repo"
    APP_SOURCE_DIR  = "/tmp/frontend-repo/src/app/frontend"
    NGINX_WEB_ROOT  = "/var/www/frontend"
    NGINX_SITE_CONF = "/etc/nginx/sites-enabled/frontend"
    BACKEND_DNS     = var.be_lb_dns
    BACKEND_PORT    = tostring(var.backend_app_port)
  }))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "frontend" {
  name                      = "frontend-asg"
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = var.public_subnet_ids

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.frontend.arn]
}