# GitHub Actions -> AWS OIDC federation
#
# Lets the CI workflow (.github/workflows/3tier-build.yaml) assume an AWS role
# via short-lived federated tokens instead of static access keys.
#
# This lives in its own Terraform state, separate from eks/infra. It used to
# be managed inside the eks/infra stack, and a `terraform destroy` of that
# stack (a routine cluster teardown) deleted these resources along with the
# cluster on 2026-08-20. CI credentials need to survive cluster teardowns, so
# they're now an independent root module with their own state file.

data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

# data "tls_certificate" "github_actions" {
#   url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
# }

# resource "aws_iam_openid_connect_provider" "github_actions" {
#   url             = "https://token.actions.githubusercontent.com"
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]

#   tags = {
#     Name = "github-actions-oidc-provider"
#   }
# }

resource "aws_iam_role" "github_actions_build" {
  name = "eks-github-actions-build-role"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          #Federated = aws_iam_openid_connect_provider.github_actions.arn
          Federated = data.aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            # GitHub's immutable subject claim format (repos created after 2026-07-15
            # embed the permanent owner_id/repo_id, so this is an exact, stable match -
            # confirmed against the actual denied CloudTrail AssumeRoleWithWebIdentity events).
            #"token.actions.githubusercontent.com:sub" = "repo:Evatee-coder@70039845/eks-microservices-gitops-platform@1337927724:ref:refs/heads/main"
            #"token.actions.githubusercontent.com:sub" = "repo:Evatee-coder@70039845/eks-microservices-gitops-platform@1354028614:*"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Evatee-coder@70039845/eks-microservices-gitops-platform@1354028614:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "github-actions-eks-build-role"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions_build.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/eks-ECRPushPullPolicy"
}





# Terraform state access policy
resource "aws_iam_policy" "terraform_state_access" {
  name = "eks-terraform-state-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::state-bucket-216989097838"
        Condition = {
          StringLike = {
            "s3:prefix" = "eks/*"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::state-bucket-216989097838/eks/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_state" {
  role       = aws_iam_role.github_actions_build.name
  policy_arn = aws_iam_policy.terraform_state_access.arn
}





resource "aws_iam_policy" "self_get_role" {
  name = "eks-github-actions-self-getrole"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iam:GetRole"]
        Resource = aws_iam_role.github_actions_build.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_self_getrole" {
  role       = aws_iam_role.github_actions_build.name
  policy_arn = aws_iam_policy.self_get_role.arn
}


resource "aws_iam_policy" "ssm_eks_ami_lookup" {
  name = "eks-github-actions-ssm-ami-lookup"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:us-east-1::parameter/aws/service/eks/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_ssm_ami" {
  role       = aws_iam_role.github_actions_build.name
  policy_arn = aws_iam_policy.ssm_eks_ami_lookup.arn
}


resource "aws_iam_policy" "eks_provisioning" {
  name = "eks-github-actions-provisioning"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EC2VPCFull"
        Effect   = "Allow"
        Action   = ["ec2:*"]
        Resource = "*"
      },
      {
        Sid    = "IAMRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider"
        ]
        Resource = "*"
      },
      {
        Sid      = "CloudWatchLogsDiscovery"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsManagement"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:TagResource",
          "logs:ListTagsForResource"
        ]
        Resource = "arn:aws:logs:us-east-1:216989097838:log-group:/aws/eks/*"
      },

      {
        Sid      = "EKSFull"
        Effect   = "Allow"
        Action   = ["eks:*"]
        Resource = "*"
      },
      {
        Sid    = "KMSForEKSEncryption"
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:ListAliases",
          "kms:ListResourceTags",
          "kms:PutKeyPolicy",
          "kms:ScheduleKeyDeletion",
          "kms:TagResource",
          "kms:EnableKeyRotation",
          "kms:GetKeyRotationStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_eks_provisioning" {
  role       = aws_iam_role.github_actions_build.name
  policy_arn = aws_iam_policy.eks_provisioning.arn
}




import {
  to = aws_iam_role.github_actions_build
  id = "eks-github-actions-build-role"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_ecr
  id = "eks-github-actions-build-role/arn:aws:iam::216989097838:policy/eks-ECRPushPullPolicy"
}
