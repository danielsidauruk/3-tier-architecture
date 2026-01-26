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

# --- IAM ---
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile"
  role = var.secret_managers_role
}

# --- Security ---
resource "aws_security_group" "backend" {
  name        = "backend-sg"
  description = "Allow traffic to/from backend application"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.security_group_frontend_id]
    description     = "Allow SSH from Frontend instances"
  }

  ingress {
    from_port       = var.backend_app_port
    to_port         = var.backend_app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_lb.id]
    description     = "Allow app traffic from load balancer"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound to internet via NAT Gateway"
  }
}

resource "aws_security_group_rule" "backend_egress_mongodb" {
  type                     = "egress"
  from_port                = var.mongodb_port
  to_port                  = var.mongodb_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = var.security_group_mongodb_id
  description              = "Allow outbound to DocumentDB Cluster"
}

resource "aws_security_group_rule" "backend_egress_redis" {
  type                     = "egress"
  from_port                = var.redis_port
  to_port                  = var.redis_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend.id
  security_group_id        = var.security_group_redis_id
  description              = "Allow outbound to Redis Cluster"
}

resource "aws_security_group" "backend_lb" {
  name        = "backend-lb-sg"
  description = "Security group for the load balancer"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.backend_app_port
    to_port         = var.backend_app_port
    protocol        = "tcp"
    security_groups = [var.security_group_frontend_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Load Balancer ---
resource "aws_lb" "backend" {
  name               = "backend-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_lb.id]
  subnets            = var.private_subnet_ids
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

# --- Launch Template & Autoscaling ---
resource "aws_launch_template" "backend" {
  name_prefix            = "backend-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.backend.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    MONGODB_ENDPOINT       = var.mongodb_endpoint
    MONGODB_PORT           = tostring(var.mongodb_port)
    REDIS_PORT             = tostring(var.redis_port)
    REDIS_PRIMARY_ENDPOINT = var.redis_primary_endpoint
    REDIS_READER_ENDPOINT  = var.redis_reader_endpoint
    MONGODB_USER           = var.mongodb_user
    SECRET_NAME            = var.secret_name
    PRIMARY_REGION         = var.primary_region
    REPO_URL               = var.repo_url
    BACKEND_PORT           = tostring(var.backend_app_port)
    REPO_CLONE_DIR         = "/tmp/backend-repo-clone"
    APP_INSTALL_DIR        = "/home/ubuntu/backend"
    LOG_DIR                = "/var/log/gunicorn"
  }))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "backend" {
  name                      = "backend-asg"
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  health_check_type         = "ELB"
  health_check_grace_period = 300
  vpc_zone_identifier       = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.backend.arn]
}