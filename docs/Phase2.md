Phase 2: Knowledge & Structure Audit
Before changing code, spend 15–20 minutes "reading" the architecture:

The Terraform Side: Look at main.tf, variables.tf, and outputs.tf. This defines the AWS infrastructure (Lambda functions, IAM roles, and CloudWatch events).

The Python Side: Look at the functions/ folder (or wherever the Python code sits). This is the logic that actually formats the ECS events and sends them to Slack.

The Glue: Notice how Terraform packages the Python code into a ZIP file to upload to AWS Lambda.
