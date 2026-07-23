data "aws_secretsmanager_secret_version" "yh_finance_latest" {
  secret_id = "YH_Finance_Api" # Simplified per our earlier discussion
}

locals {
  finance_secrets = jsondecode(data.aws_secretsmanager_secret_version.yh_finance_latest.secret_string)
}

data "aws_vpc" "default" { default = true }

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

# --- [UPDATED SECTION] ---

# 1. Reference the new role we created earlier
# (Make sure the 'aws_iam_role' resource block from the previous step is in your files)

# 2. Batch Compute Environment
resource "aws_batch_compute_environment" "fargate_env" {
  name  = "yahoo_terraform"
  type  = "MANAGED"
  state = "ENABLED"

  # UPDATED: Added the policy attachment to the existing depends_on list
  depends_on = [aws_iam_role_policy_attachment.managed_attachments]
  # UPDATED: Points to the new Terraform-managed role
  service_role = aws_iam_role.batch_ecs_task_role.arn

  compute_resources {
    type               = "FARGATE"
    max_vcpus          = 4
    subnets            = data.aws_subnets.default.ids
    security_group_ids = [data.aws_security_group.default.id]
  }
}

# 3. Job Queue
resource "aws_batch_job_queue" "fargate_queue" {
  name     = "yahoo_terraform_job_queue"
  state    = "ENABLED"
  priority = 1

  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.fargate_env.arn
  }
}

# 4. Job Definition
resource "aws_batch_job_definition" "python_app_job" {
  name = "yahoo_terraform_job_definition"
  type = "container"

  platform_capabilities = ["FARGATE"]

  # The image is now published by GitHub Actions, so we only depend on the
  # IAM policy attachment being in place before the job definition is created.
  depends_on = [
    aws_iam_role_policy_attachment.managed_attachments
  ]

  container_properties = jsonencode({
    image = "${aws_ecr_repository.python_app.repository_url}:latest"
    resourceRequirements = [
      { type = "VCPU", value = "2" },
      { type = "MEMORY", value = "4096" }
    ]

    executionRoleArn = aws_iam_role.batch_ecs_task_role.arn
    jobRoleArn       = aws_iam_role.batch_ecs_task_role.arn

    networkConfiguration = {
      assignPublicIp = "ENABLED"
    }

    environment = [
      { name = "S3_BUCKET", value = var.bucket_name }
    ]

    fargatePlatformConfiguration = { platformVersion = "LATEST" }
    runtimePlatform = {
      operatingSystemFamily = "LINUX"
      cpuArchitecture       = "X86_64"
    }
  })
}