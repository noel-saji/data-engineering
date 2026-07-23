# 1. The SNS Topic
resource "aws_sns_topic" "batch_job_updates" {
  name = "yahoo-batch-updates"
}

# 2. The Email Subscription
resource "aws_sns_topic_subscription" "email_target" {
  topic_arn = aws_sns_topic.batch_job_updates.arn
  protocol  = "email"
  endpoint  = var.email_name # <--- Update this!
}

# 3. The Permission: Allow EventBridge to talk to SNS
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.batch_job_updates.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.batch_job_updates.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.batch_job_rule.arn }
      }
    }]
  })
}