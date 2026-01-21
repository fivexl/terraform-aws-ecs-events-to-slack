PROJECT_MASTER_DOC: ECS Events to Slack
📌 Project Overview
An Infrastructure-as-Code (IaC) project designed to capture AWS ECS events and forward formatted notifications to a Slack channel. The project has been modernized as of January 20, 2026, to support modern Python packaging and secure AWS remote state management.

🛠 Tech Stack & Modernization
Infrastructure: Terraform (v1.5+)

Runtime: Python 3.12+ (Lambda)

Dependency Management: uv (PEP 621 compliant)

CI/CD Ready: Integrated Dockerfile for containerized Lambda deployment.

2026 Modernization Updates:
Migrated to uv: Replaced legacy pip workflow with uv for lightning-fast, reproducible builds via pyproject.toml and uv.lock.

Remote Backend: Successfully migrated from local state to S3 + DynamoDB locking.

Secure Secrets: Implemented .tfvars patterns to prevent Slack Webhook leakage.

☁️ Infrastructure Baseline (Company Tester Account)
The project is configured to run in the Company Tester environment.

Component	Resource / Value
AWS Account ID	471112922998
Terraform Region	eu-central-1 (Frankfurt)
S3 State Bucket	terraform-state-a6490666acaa9e18f19bdc1559e7c3acde30c9de
DynamoDB Lock Table	terraform-state-lock-a6490666acaa9e18f19bdc1559e7c3acde30c9de
