# qwen3-coder:480b-ollamafm Output: Designed by Tingle
Date: 2026-01-19_15-19-51

To **fix errors** in the `terraform-aws-ecs-events-to-slack` module — whether they're related to Terraform configuration, Lambda function behavior, or Slack integration — we need a comprehensive and methodical approach.

Below is a **detailed plan of action**, broken into logical phases based on your context and goals:

---

## 🔍 Phase 1: Understand the Problem Space

Before diving into fixing anything, clearly define what’s broken or needs improvement. This involves gathering information about:

### ✅ A. Identify the Specific Error(s)
Are you seeing issues like:
- Terraform apply fails?
- The Lambda function doesn't trigger?
- Events are not being sent to Slack?
- Slack messages aren’t formatted correctly?
- IAM permissions denied?

Use logs from:
- CloudWatch Logs for Lambda (`/aws/lambda/<function-name>`)
- EventBridge rule history (via AWS Console or CLI)
- Terraform output during apply

### ✅ B. Validate Environment Setup
Ensure that:
- You’re using compatible AWS provider versions (`>= 3.69`, per docs).
- Your Terraform state is clean and up-to-date.
- All environment variables needed by Lambda (like `SLACK_WEBHOOK_URL`) are properly configured.

---

## 🧱 Phase 2: Review Infrastructure Code (Terraform Side)

Review these files thoroughly:
- `main.tf`: Defines resources such as EventBridge rules, Lambda targets, IAM roles/policies.
- `variables.tf`: Ensure all required inputs have defaults or are passed in correctly.
- `outputs.tf`: Verify exported values match expectations.

### 🔎 Common Issues & Fixes:

#### 1. **Missing Permissions**
Make sure the Lambda execution role has access to:
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`
- If using Secrets Manager or SSM, add `secretsmanager:GetSecretValue` or `ssm:GetParameter`

Fix example:
```hcl
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_policy" "lambda_secrets_access" {
  name = "${var.name}-secrets-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameter"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_access_attach" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_secrets_access.arn
}
```

#### 2. **EventBridge Rule Pattern Matching**
Verify that the pattern matches actual ECS events.

Example of correct event pattern:
```json
{
  "source": ["aws.ecs"],
  "detail-type": ["ECS Service Deployment State Change", "ECS Task State Change"]
}
```

If this doesn't align with real events, the rule won’t fire.

Check current events via AWS EventBridge console → Replays → Sample Events.

#### 3. **Lambda Timeout / Memory Settings**
Default settings may be too low. Increase timeout/memory if logs show timeouts or throttling.

Update in `module.slack_notifications`:
```hcl
timeout     = 60
memory_size = 256
```

---

## 🐍 Phase 3: Debug Python Logic (Lambda Function)

This is where most custom logic lives.

### 📌 Key Areas to Inspect:

#### 1. **Environment Variables Handling**

Ensure:
- `SLACK_WEBHOOK_URL_SOURCE_TYPE` is either `"text"`, `"secretsmanager"`, or `"ssm"`
- `SLACK_WEBHOOK_URL` points to a valid secret name or URL depending on source type.

Test locally using something like:
```bash
export LOG_LEVEL=DEBUG
export SLACK_WEBHOOK_URL_SOURCE_TYPE=text
export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/TXXXXX/BXXXXX/XXXXX
python functions/slack_notifications.py
```

Add debug logging inside `get_slack_credentials()`:
```python
log.debug(f"Fetching credential from {source_type}: {value}")
```

#### 2. **Error Handling Around Webhook Calls**

In case of HTTP failures when posting to Slack, ensure proper error handling exists:
```python
conn = http.client.HTTPSConnection("hooks.slack.com")
try:
    conn.request("POST", path, payload_json, headers)
    response = conn.getresponse()
    log.info(f"Slack response status: {response.status}, reason: {response.reason}")
except Exception as e:
    log.error(f"Failed to send message to Slack: {e}")
finally:
    conn.close()
```

Also check if the payload structure conforms to Slack's expected format:
```python
payload = {
    "text": "ECS Event Notification",
    "attachments": [{
        "color": "#FF0000",  # red for errors
        "fields": [
            {"title": "Service", "value": service_name},
            {"title": "Status", "value": task_status}
        ]
    }]
}
```

#### 3. **Parser Logic (`ecs_events_parser`)**
Ensure it handles edge cases gracefully.

Example fix for missing keys:
```python
def ecs_events_parser(detail_type, detail):
    emoji_event_type = {...}
    emoji_event_name = {...}
    emoji_task_status = {...}

    message = ""

    # Safely extract fields
    service_name = detail.get("serviceName", "Unknown")
    cluster_arn = detail.get("clusterArn", "")
    status = detail.get("lastStatus", "Unknown")

    event_type = detail.get("eventType", "INFO")
    event_name = detail.get("eventName", "")

    color_map = {
        "ERROR": "#FF0000",
        "WARN": "#FFA500",
        "INFO": "#008000"
    }

    color = color_map.get(event_type, "#CCCCCC")

    return {
        "text": f"{emoji_event_type.get(event_type, '')} *{event_name}* - {service_name}",
        "attachments": [{
            "color": color,
            "fields": [
                {"title": "Cluster ARN", "value": cluster_arn},
                {"title": "Last Status", "value": status}
            ]
        }]
    }
```

---

## ⚙️ Phase 4: Test Locally Before Deploying

Use tools like [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html), or test individual parts:

### Option 1: Use Dockerized Lambda Runtime
Build and run Lambda locally:
```bash
docker build -t lambda-test .
docker run -e ... lambda-test
```

### Option 2: Mock Event Payloads
Create sample payloads matching ECS EventBridge events and invoke the handler directly:
```python
event_sample = {
  "version": "0",
  "id": "abcd1234-abcd-1234-abcd-1234abcd1234",
  "detail-type": "ECS Service Deployment State Change",
  "source": "aws.ecs",
  "account": "123456789012",
  "time": "2025-04-05T12:34:56Z",
  "region": "us-east-1",
  "resources": [],
  "detail": {
    "eventType": "INFO",
    "eventName": "SERVICE_DEPLOYMENT_COMPLETED",
    "clusterArn": "arn:aws:ecs:us-east-1:123456789012:cluster/my-cluster",
    "serviceName": "my-service"
  }
}

handler(event_sample, None)
```

---

## 🛠️ Phase 5: Fix & Improve Based on Findings

Now that you've identified the root cause(s), implement fixes across layers:

### Terraform Fixes
- Adjust IAM policies
- Tune Lambda config (timeout/memory)
- Refine EventBridge patterns

### Lambda Code Fixes
- Add robust input validation
- Handle exceptions gracefully
- Enhance logging and debugging capabilities

### Configuration Improvements
- Support multiple environments (dev/staging/prod)
- Allow dynamic Slack channels or user mentions
- Add alert deduplication or filtering options

---

## 📈 Phase 6: Monitor After Deployment

Once deployed, monitor:
- Lambda invocation success/failure rates
- CloudWatch logs for any new exceptions
- Slack channel to confirm delivery
- Optional: Set up alerts on Lambda errors using CloudWatch Alarms

---

## 🧪 Bonus Tips for Testing & Maintenance

### Unit Tests
Write simple unit tests for key functions:
```python
import unittest
from slack_notifications import ecs_events_parser

class TestECSEventParser(unittest.TestCase):
    def test_service_deployment_completed(self):
        result = ecs_events_parser("ECS Service Deployment State Change", {
            "eventType": "INFO",
            "eventName": "SERVICE_DEPLOYMENT_COMPLETED",
            "serviceName": "test-svc",
            "clusterArn": "arn:aws:ecs:...",
            "lastStatus": "ACTIVE"
        })
        self.assertIn("✅ SERVICE_DEPLOYMENT_COMPLETED", result["text"])
```

Run with:
```bash
python -m unittest discover
```

### Pre-commit Hooks
Install pre-commit hooks to validate Terraform formatting:
```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.75.0
    hooks:
      - id: terraform_fmt
      - id: terraform_docs
```

Initialize:
```bash
pre-commit install
```

---

## 🧭 Summary Plan Recap

| Step | Action |
|------|--------|
| 1 | Define exact problem/error symptoms |
| 2 | Audit Terraform infrastructure |
| 3 | Analyze Lambda Python code logic |
| 4 | Test components locally before redeploying |
| 5 | Apply fixes iteratively and safely |
| 6 | Monitor post-deployment performance |
| 7 | Add tests, documentation, CI automation |

By following this structured process, you’ll resolve existing bugs efficiently and improve maintainability long-term.

Let me know if you want help writing specific patches or reviewing diffs!