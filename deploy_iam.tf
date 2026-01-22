# This variable is needed to configure the trust policy
variable "github_repo" {
  description = "The GitHub repository in format 'org/repo' (e.g., 'fivexl/ecs-events-to-slack')"
  type        = string
}

# The OIDC provider is assumed to exist in the account already.
# We reference it by constructing the ARN standard for GitHub.
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_ci_role" {
  name = "github-ci-ecr-push-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # STRICT SECURITY: Only allow the main branch of this specific repo
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecr_push_policy" {
  name = "ecr-push-limited"
  role = aws_iam_role.github_ci_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetAuthorizationToken"
        Effect = "Allow"
        Action = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "AllowPushToSpecificRepo"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        # Restrict permissions strictly to the repo created in main.tf
        Resource = aws_ecr_repository.lambda_repo.arn
      }
    ]
  })
}
