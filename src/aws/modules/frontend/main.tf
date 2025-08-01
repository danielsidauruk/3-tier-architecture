resource "aws_security_group" "frontend" {
  name        = "${var.application_name}-frontend-sg"
  description = "Allow SSH and web traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name             = "${var.application_name}-frontend-sg"
    application_name = var.application_name
  }
}

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

resource "aws_instance" "frontend" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  security_groups = [aws_security_group.frontend.id]
  subnet_id       = var.public_subnet_ids[0]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    REPO_URL        = var.repo_url
    REPO_CLONE_DIR  = "/tmp/frontend-repo"
    APP_SOURCE_DIR  = "/tmp/frontend-repo/src/app/frontend"
    NGINX_WEB_ROOT  = "/var/www/frontend"
    NGINX_SITE_CONF = "/etc/nginx/sites-enabled/frontend"
    BACKEND_IP      = var.backend_private_ip
    BACKEND_PORT    = tostring(var.backend_app_port)
  })

  tags = {
    Name        = "${var.application_name}-frontend"
    application = var.application_name
  }
}
