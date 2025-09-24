
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

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

  tags = {
    Name        = "frontend"
    application = var.application_name
  }

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

  tag {
    key                 = "Name"
    value               = "frontend"
    propagate_at_launch = true
  }

  tag {
    key                 = "application"
    value               = var.application_name
    propagate_at_launch = true
  }
}
