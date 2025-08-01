resource "aws_security_group" "backend" {
  name        = "${var.application_name}-backend-sg"
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
    security_groups = [var.security_group_frontend_id]
    description     = "Allow app traffic from Frontend instances"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound to internet via NAT Gateway"
  }

  tags = {
    Name        = "${var.application_name}-backend-sg"
    application = var.application_name
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

resource "aws_iam_role" "ec2_secrets_manager_role" {
  name = "${var.application_name}-ec2-secrets-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "${var.application_name}-secrets-manager-policy"
  description = "Policy to allow reading secrets from AWS Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [var.mongodb_secret_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager_attachment" {
  role       = aws_iam_role.ec2_secrets_manager_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.application_name}-ec2-profile"
  role = aws_iam_role.ec2_secrets_manager_role.name
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

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[0]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.backend.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    MONGODB_ENDPOINT = var.mongodb_endpoint
    MONGODB_PORT     = tostring(var.mongodb_port)
    REDIS_ENDPOINT   = var.redis_endpoint
    REDIS_PORT       = tostring(var.redis_port)
    MONGODB_USER     = var.mongodb_user
    SECRET_NAME      = var.secret_name
    PRIMARY_REGION   = var.primary_region
    REPO_URL         = var.repo_url
    REPO_CLONE_DIR   = "/tmp/backend-repo-clone"
    APP_INSTALL_DIR  = "/home/ubuntu/backend"
    LOG_DIR          = "/var/log/gunicorn"
  })

  tags = {
    Name        = "${var.application_name}-backend"
    application = var.application_name
  }
}
