# IAM role for EC2 instances with Terraform automation and S3 access
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_tf_automation_role" {
  name               = var.ec2_tf_automation_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = {
    Name = var.ec2_tf_automation_role_name
  }
}

# EC2 full access policy for Terraform automation
data "aws_iam_policy_document" "ec2_access" {
  statement {
    actions   = ["ec2:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ec2_policy" {
  name   = "${var.ec2_tf_automation_role_name}-ec2-policy"
  role   = aws_iam_role.ec2_tf_automation_role.id
  policy = data.aws_iam_policy_document.ec2_access.json
}

# Secrets Manager access policy
data "aws_iam_policy_document" "secrets" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:DescribeSecret"
    ]
    resources = var.cyberark_secret_arn
  }
}

resource "aws_iam_role_policy" "secrets_policy" {
  name   = "${var.ec2_tf_automation_role_name}-secrets-policy"
  role   = aws_iam_role.ec2_tf_automation_role.id
  policy = data.aws_iam_policy_document.secrets.json
}

# IAM full access policy
data "aws_iam_policy_document" "iam_access" {
  statement {
    actions   = ["iam:*"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "iam_policy" {
  name   = "${var.ec2_tf_automation_role_name}-iam-policy"
  role   = aws_iam_role.ec2_tf_automation_role.id
  policy = data.aws_iam_policy_document.iam_access.json
}

# S3 bucket access policy
data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      var.s3_bucket_arn,
      "${var.s3_bucket_arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "s3_policy" {
  name   = "${var.ec2_tf_automation_role_name}-s3-policy"
  role   = aws_iam_role.ec2_tf_automation_role.id
  policy = data.aws_iam_policy_document.s3_access.json
}

# Instance profile for EC2 instances
resource "aws_iam_instance_profile" "ec2_tf_automation_instance_profile" {
  name = "${var.ec2_tf_automation_role_name}-profile"
  role = aws_iam_role.ec2_tf_automation_role.name
}
