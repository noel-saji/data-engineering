# Data Engineering/Data OPs for Financial Stock Market Pipeline 🛠️📊


| | | | |
| :---: | :--: | :---: | :---: |
| <img src="images/aws_logo.png" width="40"> | <img src="images/docker_logo.png" width="40"> | <img src="images/python_logo.png" width="40"> | <img src="images/terraform_logo.png" width="40"> |
| **AWS** | **Docker** | **Python** | **Terraform** |


### Project Overview: Serverless ELT Pipeline for Yahoo Finance

This project implements a **serverless, event-driven ELT pipeline** designed for the automated, hourly ingestion and transformation of **Yahoo Finance** stock data. The system captures raw market metrics—including OHLC prices and trading volumes—and processes them through a transformation layer that converts raw values into currency-normalized prices, adjusted closing rates, and hourly percentage changes.

### Technical Implementation

*   ✅ **Data Logic & Containerization**: Core ingestion and transformation are handled by **Python** scripts. These are packaged into **Docker** images and stored in **Amazon ECR** to ensure environment consistency.
*   ✅ **Orchestration & Compute**: **AWS Batch** manages the lifecycle of the containerized jobs, dynamically provisioning compute resources only when needed. These jobs are triggered hourly using **Amazon EventBridge**.
*   ✅ **Infrastructure as Code (IaC)**: The entire cloud environment—including networking, compute, and security—is provisioned and managed using **Terraform**, providing a repeatable and version-controlled deployment.
*   ✅ **Monitoring & Alerting**: Reliability is maintained through **Amazon SNS**, which sends automated email notifications to administrators in the event of a pipeline or job failure.
*   ✅ **Data Lake & Analytics**: Transformed data is registered in the **AWS Glue Data Catalog**. Users can perform high-performance SQL analysis on historical market trends via **Amazon Athena**, leveraging optimized **S3 data partitioning**.


---

## 1. Prerequisites
Before setting up the project, ensure you have the following installed and configured:

*   **AWS Account**: An active [AWS Free Tier](https://aws.amazon.com) or professional account.
*   **AWS CLI**: Installed and configured with your local machine. Refer to the [AWS CLI Setup Guide](https://docs.aws.amazon.com).
*   **Terraform**: Version 1.0 or higher. [Download Terraform](https://www.terraform.io).
*   **Docker**: Ensure Docker is installed and running. [Docker Desktop](https://www.docker.com).
*   **Yahoo API**: Ensure you signup and retrieve Yahoo API key from [Yahoo API](https://financeapi.net/).

---

## 2. Initialisation

> [!IMPORTANT]
> **Manual AWS Setup Tasks**
> The following steps must be completed in the [AWS Management Console](https://console.aws.amazon.com) before running the automation scripts.

### Environment Setup
Create a `terraform.tfvars` file inside the `terraform/` directory and add the following:

```makefile
aws_region  = "ap-south-1"
repo_name   = "your-repo-name"
bucket_name = "your-bucket-name"
email_name  = "your.email@gmail.com"
github_repo = "your-org/your-repo"   # repo allowed to assume the GitHub OIDC role
```

> [!NOTE]
> `aws_region`, `repo_name`, and `github_repo` must match the `env` block in
> `.github/workflows/yahoo-finance-image.yml`, which builds and pushes the
> container image (see section 4).

### IAM Configuration
1.  **Create IAM User**: From your **Root Account**, create a new IAM user.
2.  **Permissions**: Attach the `AdministratorAccess` policy to this user.
3.  **Security Credentials**: Generate an **Access Key** and **Secret Access Key**. Save these locally for CLI configuration.

### Secrets Management
Navigate to [AWS Secrets Manager](https://aws.amazon.com) and create a secret containing the following keys:
*   `Yahoo_API`

### Storage Layer
Create an **S3 Bucket** (e.g., `my-data-engineering-project`) and manually create the following folder structure:
*   `raw/`
*   `transformed/`
  
> [!IMPORTANT]
> **Enter the bucket name inside tfvars Terraform file or change Bucket name inside raw_script and transforned scripts(Python)**
> After creating S3 bucket Name, Copy this Bucket name and paste it inside raw and transformed script files on Bucket names initialised
---

## 3. Deployment & Execution

### Pull the Repository
Clone the project to your local environment:
```bash
cd data-engineering-project
git clone https://github.com/noel-saji/aws-data-engineering-yahoo-finance.git
```

## 🛠 4. Infrastructure as Code (IaC)

This project leverages **Terraform** to provision and manage cloud resources consistently. All configuration files are housed within the `terraform/` directory.

### 📁 Directory Structure

```text
terraform/
├── main.tf         # AWS provider + ECR repository
├── iamrole.tf      # IAM roles: Batch/ECS task, EventBridge scheduler, GitHub OIDC
├── batch.tf        # AWS Batch compute env, job queue & job definition
├── eventbridge.tf  # Hourly schedule, event rule, SNS target
├── glue.tf         # Glue catalog database, table & crawler
├── sns.tf          # SNS topic, email subscription & policy
├── variables.tf    # Input variables
└── outputs.tf      # ECR URL + GitHub Actions role ARN
```

### 🐳 Container Image (CI/CD)

The Docker image is **not** built by Terraform. Terraform only provisions the
**ECR repository**; the image is built and pushed by a **GitHub Actions**
workflow (`.github/workflows/yahoo-finance-image.yml`) that authenticates to AWS
using **OIDC** — no long-lived access keys are stored in GitHub.

**How auth works:**
* `iamrole.tf` registers GitHub's OIDC provider and creates an IAM role
  (`yahoo_terraform_github_oidc_role`) whose trust policy is scoped to
  `repo:<github_repo>:environment:main` and grants only ECR push permissions.
* The workflow runs in the GitHub **`main` environment** and reconstructs the
  role ARN from a single secret — your **AWS account ID**.

**One-time GitHub setup** (after `terraform apply` has created the role):
1. In the repo: **Settings → Environments → New environment → `main`**.
2. Add an environment **secret** `AWS_ACCOUNT_ID` = your 12-digit AWS account ID.

The workflow then runs automatically on any push to `main` that changes
`yahoo_finance/src/**` or `yahoo_finance/Dockerfile`, pushing both `:latest` and
a `:<git-sha>` tag. It can also be triggered manually via **Run workflow**.

> [!IMPORTANT]
> Only one OIDC provider for `token.actions.githubusercontent.com` can exist per
> AWS account. If yours already has one, remove the
> `aws_iam_openid_connect_provider.github` block from `iamrole.tf` and
> `terraform import` the existing provider instead.

---

## 🚀 Deployment Workflow

All Terraform commands are run from the `terraform/` directory:

```bash
cd terraform
```

### 1️⃣ Initialize

Download the required AWS provider and initialize Terraform:

```bash
terraform init
```
### 2️⃣ Plan

Preview the changes Terraform will apply to your infrastructure:

```bash
terraform plan
```

### 3️⃣ Apply

Deploy the resources to AWS:

```bash
terraform apply
```

## 🧹 5. Cleanup

To delete all provisioned AWS resources and prevent unnecessary costs:

```bash
terraform destroy
```


