# IAM role for EC2 instances to access S3 bucket
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_s3_role" {
  name               = var.ec2_s3_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = {
    Name = var.ec2_s3_role_name
  }
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
  name   = "${var.ec2_s3_role_name}-s3-policy"
  role   = aws_iam_role.ec2_s3_role.id
  policy = data.aws_iam_policy_document.s3_access.json
}

# Instance profile for EC2 instances
resource "aws_iam_instance_profile" "ec2_s3_instance_profile" {
  name = "${var.ec2_s3_role_name}-profile"
  role = aws_iam_role.ec2_s3_role.name
}
