# 1. Create the SQS Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name = "yahoo_terrafrom_sqs"
}

# 2. Create the EventBridge Schedule
resource "aws_scheduler_schedule" "yahoo_schedule" {
  name       = "yahoo_terraform_scheduler"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  # Updated to run every 1 hour
  schedule_expression = "rate(1 hour)"

  # Optional but recommended to ensure permissions are ready
  depends_on = [aws_iam_role_policy.scheduler_batch_policy]

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:batch:submitJob"
    role_arn = aws_iam_role.scheduler_role.arn

    input = jsonencode({
      JobDefinition = aws_batch_job_definition.python_app_job.arn
      JobName       = "yahoo_scheduled_run"
      JobQueue      = aws_batch_job_queue.fargate_queue.arn
    })

    dead_letter_config {
      arn = aws_sqs_queue.dlq.arn
    }
  }
}


# 3. The Rule: Filtered specifically to AWS Batch Job Definition
resource "aws_cloudwatch_event_rule" "batch_job_rule" {
  name        = "yahoo-terraform-event-rule"
  description = "Alerts only for the yahoo_terraform_job_definition"

  event_pattern = jsonencode({
    "source" : ["aws.batch"],
    "detail-type" : ["Batch Job State Change"],
    "detail" : {
      # This ensures the rule ONLY applies to this specific job
      "jobDefinition" : [aws_batch_job_definition.python_app_job.arn],
      "status" : ["FAILED"]
    }
  })
}

# 4. The Target: SNS Topic
# The Target: Now with the Input Transformer
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.batch_job_rule.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.batch_job_updates.arn

  input_transformer {
    # a. Map the JSON fields from the Batch event to variables
    input_paths = {
      jobDefinition = "$.detail.jobDefinition"
      jobName       = "$.detail.jobName"
      jobQueue      = "$.detail.jobQueue"
      status        = "$.detail.status"
    }

    # b. Define the Template using those variables
    # Note: <status> at the beginning acts as the "Subject line" in SNS emails
    input_template = <<EOF
"<status>: Job Name = <jobName>"
"Job Definition = <jobDefinition>"
"Status = <status>"
EOF
  }
}



