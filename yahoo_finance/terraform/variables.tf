variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "repo_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "my-python-app"
}

variable "bucket_name" {
  description = "Name of the S3 Bucket"
  type        = string
  default     = "bucket-name"
}


variable "email_name" {
  description = "Name of the email used to recieve SNS notifications"
  type        = string
  default     = "youremail@gmail.com"
}

variable "github_repo" {
  description = "GitHub repository (owner/name) allowed to assume the OIDC role"
  type        = string
  default     = "noel-saji/data-engineering"
}

variable "github_environment" {
  description = "GitHub environment the OIDC role is scoped to (must match `environment:` in the workflow)"
  type        = string
  default     = "main"
}

variable "github_oidc_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions via OIDC (must match the workflow)"
  type        = string
  default     = "yahoo_terraform_github_oidc_role"
}
