# --- IAM Role ---
resource "aws_iam_role" "ec2_secrets_manager_role" {
  name = "ec2-secrets-manager-role"

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

# --- IAM Policies ---
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "secrets-manager-policy"
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

resource "aws_iam_policy" "resource_metadata_policy" {
  name        = "resource-metadata-policy"
  description = "Policy to allow reading metadata from DocumentDB and ElastiCache"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowResourceMetadataRead"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "elasticache:DescribeReplicationGroups",
          "elasticache:DescribeCacheClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# --- IAM Policy Attachments ---
resource "aws_iam_role_policy_attachment" "secrets_manager_attachment" {
  role       = aws_iam_role.ec2_secrets_manager_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_role_policy_attachment" "resource_metadata_attachment" {
  role       = aws_iam_role.ec2_secrets_manager_role.name
  policy_arn = aws_iam_policy.resource_metadata_policy.arn
}