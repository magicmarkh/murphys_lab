#get the current account number
data "aws_caller_identity" "current" {}

#create the policy
resource "aws_iam_policy" "SecretsHubOnboardingPolicy" {
  name        = "SecretsHubOnboardingPolicy"
  description = "Permissions required to onboard Secrets Hub"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Condition" : {
            "StringEquals" : {
              "aws:RequestTag/Sourced by CyberArk" : [
                ""
              ]
            }
          },
          "Action" : "secretsmanager:CreateSecret",
          "Resource" : "arn:aws:secretsmanager:${var.SecretsManagerRegion}:${data.aws_caller_identity.current.account_id}:secret:*",
          "Effect" : "Allow"
        },
        {
          "Condition" : {
            "StringEquals" : {
              "aws:RequestedRegion" : "${var.SecretsManagerRegion}"
            }
          },
          "Action" : "secretsmanager:ListSecrets",
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Condition" : {
            "StringEqualsIgnoreCase" : {
              "aws:ResourceTag/Sourced by CyberArk" : ""
            }
          },
          "Action" : [
            "secretsmanager:UpdateSecret",
            "secretsmanager:PutSecretValue",
            "secretsmanager:DeleteSecret",
            "secretsmanager:DescribeSecret",
            "secretsmanager:TagResource",
            "secretsmanager:UntagResource"
          ],
          "Resource" : "arn:aws:secretsmanager:${var.SecretsManagerRegion}:${data.aws_caller_identity.current.account_id}:secret:*",
          "Effect" : "Allow"
        },
        {
          "Condition" : {
            "StringNotEqualsIgnoreCase" : {
              "aws:ResourceTag/Sourced by CyberArk" : ""
            },
            "ForAllValues:StringEqualsIgnoreCase" : {
              "aws:TagKeys" : [
                "Sourced by CyberArk",
                "CyberArk Extended Access"
              ]
            }
          },
          "Action" : [
            "secretsmanager:TagResource",
            "secretsmanager:UntagResource"
          ],
          "Resource" : "arn:aws:secretsmanager:${var.SecretsManagerRegion}:${data.aws_caller_identity.current.account_id}:secret:*",
          "Effect" : "Allow"
        },
        {
          "Condition" : {
            "StringEqualsIgnoreCase" : {
              "aws:ResourceTag/CyberArk Extended Access" : "true"
            }
          },
          "Action" : [
            "secretsmanager:GetSecretValue"
          ],
          "Resource" : "arn:aws:secretsmanager:${var.SecretsManagerRegion}:${data.aws_caller_identity.current.account_id}:secret:*",
          "Effect" : "Allow"
        }
      ]
    }
  )
}

#create the role
resource "aws_iam_role" "SecretsHubOnboardingRole" {
  name = "us-ent-east-SecretsHubOnboardingRole"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [{
        Effect = "Allow",
        Principal = {
          AWS = "${var.CyberArkSecretsHubRoleARN}"
        },
        Action = "sts:AssumeRole"
      }]
    }
  )
}

resource "aws_iam_role_policy_attachment" "cyberark_secrets_hub_policy_attachment" {
  role = aws_iam_role.SecretsHubOnboardingRole.name
  policy_arn = aws_iam_policy.SecretsHubOnboardingPolicy.arn
}