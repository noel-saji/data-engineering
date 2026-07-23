provider "aws" {
  region = var.aws_region # <--- VARIABLE USED HERE
}

resource "aws_ecr_repository" "python_app" {
  name                 = var.repo_name # <--- VARIABLE USED HERE
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# The Docker image is built and pushed to this repository by GitHub Actions
# (.github/workflows/yahoo-finance-image.yml) using the OIDC role defined in
# iamrole.tf. Terraform only provisions the ECR repository itself.
