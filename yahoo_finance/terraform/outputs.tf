# -----------------------------------------------------------------------------
# ECR
# -----------------------------------------------------------------------------
output "ecr_repository_arn" {
  description = "ARN of the ECR repository the image is pushed to"
  value       = aws_ecr_repository.python_app.arn
}

# -----------------------------------------------------------------------------
# IAM roles
# -----------------------------------------------------------------------------
output "batch_ecs_task_role_arn" {
  description = "ARN of the IAM role used by Batch/ECS tasks and the Glue crawler"
  value       = aws_iam_role.batch_ecs_task_role.arn
}

output "scheduler_role_arn" {
  description = "ARN of the IAM role EventBridge Scheduler uses to submit Batch jobs"
  value       = aws_iam_role.scheduler_role.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role GitHub Actions assumes via OIDC"
  value       = aws_iam_role.github_actions_ecr.arn
}

# -----------------------------------------------------------------------------
# AWS Batch
# -----------------------------------------------------------------------------
output "batch_compute_environment_arn" {
  description = "ARN of the Fargate Batch compute environment"
  value       = aws_batch_compute_environment.fargate_env.arn
}

output "batch_job_queue_arn" {
  description = "ARN of the Batch job queue"
  value       = aws_batch_job_queue.fargate_queue.arn
}

output "batch_job_definition_arn" {
  description = "ARN of the Batch job definition"
  value       = aws_batch_job_definition.python_app_job.arn
}

# -----------------------------------------------------------------------------
# EventBridge / SQS
# -----------------------------------------------------------------------------
output "eventbridge_schedule_arn" {
  description = "ARN of the EventBridge schedule that triggers the hourly job"
  value       = aws_scheduler_schedule.yahoo_schedule.arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule that fires on Batch job failure"
  value       = aws_cloudwatch_event_rule.batch_job_rule.arn
}

output "dlq_arn" {
  description = "ARN of the SQS dead-letter queue"
  value       = aws_sqs_queue.dlq.arn
}

# -----------------------------------------------------------------------------
# Glue
# -----------------------------------------------------------------------------
output "glue_database_arn" {
  description = "ARN of the Glue catalog database"
  value       = aws_glue_catalog_database.my_database.arn
}

output "glue_table_arn" {
  description = "ARN of the Glue catalog table"
  value       = aws_glue_catalog_table.my_table.arn
}

output "glue_crawler_arn" {
  description = "ARN of the Glue crawler"
  value       = aws_glue_crawler.my_crawler.arn
}

# -----------------------------------------------------------------------------
# SNS
# -----------------------------------------------------------------------------
output "sns_topic_arn" {
  description = "ARN of the SNS topic for job failure alerts"
  value       = aws_sns_topic.batch_job_updates.arn
}
