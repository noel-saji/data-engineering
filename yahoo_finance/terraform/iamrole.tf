# 1. Define the IAM Role and the Trust Policy (Trusted Entities)
resource "aws_iam_role" "batch_ecs_task_role" {
  name = "BatchEcsTaskTerraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "batch.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Attach the Managed Policies from your image
locals {
  policies = [
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AWSBatchFullAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
  ]
}

resource "aws_iam_role_policy_attachment" "managed_attachments" {
  for_each   = toset(local.policies)
  role       = aws_iam_role.batch_ecs_task_role.name
  policy_arn = each.value
}


# 3. IAM Role for EventBridge to trigger Batch
resource "aws_iam_role" "scheduler_role" {
  name = "yahoo_terraform_scheduler_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "scheduler_batch_policy" {
  name = "allow_batch_submit"
  role = aws_iam_role.scheduler_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "batch:SubmitJob"
        Resource = [
          aws_batch_job_definition.python_app_job.arn,
          aws_batch_job_queue.fargate_queue.arn
        ]
      },
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.dlq.arn
      }
    ]
  })
}

# --- GitHub Actions OIDC: lets the workflow push the Docker image to ECR ---
# without long-lived AWS keys. Only the AWS account ID is stored in GitHub
# (as a secret); the role ARN is reconstructed in the workflow.

# 4. Register GitHub's OIDC provider in this AWS account.
# NOTE: only ONE provider per URL can exist per account. If you already have
# this provider, remove this block and use a data source / `terraform import`.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# 5. Role the GitHub Actions workflow assumes via OIDC.
# Trust is scoped to a single repo + GitHub environment, so only workflows
# running in the "main" environment of your repo can assume it.
resource "aws_iam_role" "github_actions_ecr" {
  name = var.github_oidc_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRoleWithWebIdentity"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:environment:${var.github_environment}"
        }
      }
    }]
  })
}

# 6. Minimal ECR push permissions for the workflow role.
resource "aws_iam_role_policy" "github_actions_ecr_policy" {
  name = "github-actions-ecr-push"
  role = aws_iam_role.github_actions_ecr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "GetAuthToken"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid    = "PushToRepo"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = aws_ecr_repository.python_app.arn
      }
    ]
  })
}