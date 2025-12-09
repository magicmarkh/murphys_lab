# 1) IAM role & instance profile so EC2 can call Secrets Manager & STS
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_asm_role" {
  name               = var.ec2_aws_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

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
  role   = aws_iam_role.ec2_asm_role.id
  policy = data.aws_iam_policy_document.secrets.json
}

resource "aws_iam_instance_profile" "us_ent_east_ec2_asm_instance_profile" {
  name = "us-ent-east-ec2-connector-profile"
  role = aws_iam_role.ec2_asm_role.name
}