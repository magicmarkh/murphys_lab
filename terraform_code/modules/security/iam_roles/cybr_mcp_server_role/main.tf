# IAM role & instance profile for CyberArk MCP Server with Secrets Manager and ECR access

# EC2 assume role policy
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Create the IAM role
resource "aws_iam_role" "cybr_mcp_server_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

# Secrets Manager policy
data "aws_iam_policy_document" "secrets" {
  statement {
    actions   = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:DescribeSecret"
    ]
    resources = var.cyberark_secret_arn
  }
}

resource "aws_iam_role_policy" "secrets_policy" {
  name   = "secrets_manager_access"
  role   = aws_iam_role.cybr_mcp_server_role.id
  policy = data.aws_iam_policy_document.secrets.json
}

# ECR policy for pulling images
data "aws_iam_policy_document" "ecr" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ecr_policy" {
  name   = "ecr_pull_access"
  role   = aws_iam_role.cybr_mcp_server_role.id
  policy = data.aws_iam_policy_document.ecr.json
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "cybr_mcp_server_instance_profile" {
  name = var.instance_profile_name
  role = aws_iam_role.cybr_mcp_server_role.name
}