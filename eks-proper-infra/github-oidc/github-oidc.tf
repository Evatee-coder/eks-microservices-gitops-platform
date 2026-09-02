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


import {
  to = aws_iam_role.github_actions_build
  id = "eks-github-actions-build-role"
}

import {
  to = aws_iam_role_policy_attachment.github_actions_ecr
  id = "eks-github-actions-build-role/arn:aws:iam::216989097838:policy/eks-ECRPushPullPolicy"
}
