
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

resource "aws_launch_template" "backend" {
  name_prefix            = "${var.application_name}-backend-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.backend.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    MONGODB_ENDPOINT = var.mongodb_endpoint
    MONGODB_PORT     = tostring(var.mongodb_port)
    REDIS_ENDPOINT   = var.redis_endpoint
    REDIS_PORT       = tostring(var.redis_port)
    MONGODB_USER     = var.mongodb_user
    SECRET_NAME      = var.secret_name
    PRIMARY_REGION   = var.primary_region
    REPO_URL         = var.repo_url
    BACKEND_PORT     = tostring(var.backend_app_port)
    REPO_CLONE_DIR   = "/tmp/backend-repo-clone"
    APP_INSTALL_DIR  = "/home/ubuntu/backend"
    LOG_DIR          = "/var/log/gunicorn"
  }))

  tags = {
    Name        = "${var.application_name}-backend"
    application = var.application_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "backend" {
  name                      = "${var.application_name}-backend-asg"
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

  tag {
    key                 = "Name"
    value               = "${var.application_name}-backend"
    propagate_at_launch = true
  }

  tag {
    key                 = "application"
    value               = var.application_name
    propagate_at_launch = true
  }
}
