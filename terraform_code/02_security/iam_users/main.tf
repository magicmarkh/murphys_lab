# =====================================================================
# IAM User
# =====================================================================
resource "aws_iam_user" "this" {
  name = var.iam_username
  path = var.iam_user_path

  tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
    }
  )
}

# =====================================================================
# IAM Access Key - Data Source (existing key)
# Note: Using data source instead of resource due to import bug in AWS provider
# The access key exists and is referenced here, but not managed by Terraform
# This allows us to output the key ID for CyberArk integration
# =====================================================================
data "aws_iam_access_keys" "existing" {
  user = aws_iam_user.this.name
}
