locals {
  # Define the default params for each supported ECS event type (`detail_type`).
  # These params will be used if the corresponging rule was not overriden from the module caller explicitly.
  default_event_rules = {
    ECSTaskStateChange = {
      detail_type = "ECS Task State Change"
      detail = {
        lastStatus = ["STOPPED"]
      }
    }

    ECSDeploymentStateChange = {
      detail_type = "ECS Deployment State Change"
      detail = {
        eventType = ["ERROR"]
      }
    }

    ECSServiceAction = {
      detail_type = "ECS Service Action"
      detail = {
        eventType = ["WARN", "ERROR"]
      }
    }
  }

  # Update the params which were overridden by the module user and discard those rules which were set to {} explicitly
  event_rules = { for rule, params in local.default_event_rules : rule => merge(params, try(var.event_rules[rule], {})) if length(try(var.event_rules[rule], {})) > 0 }
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = local.event_rules

  name_prefix = "${var.name}-${each.key}"
  event_pattern = jsonencode({
    source      = [try(each.value.source, "aws.ecs")]
    detail-type = [try(each.value.detail_type, "")]
    detail      = each.value.detail
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = local.event_rules

  target_id = "${var.name}-${each.key}"
  arn       = module.slack_notifications.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.this[each.key].name
}

module "slack_notifications" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "3.1.0"

  function_name = var.name
  description   = "Receive events from EventBridge and send them to Slack"
  handler       = "slack_notifications.lambda_handler"
  source_path   = "${path.module}/functions/slack_notifications.py"
  runtime       = "python3.9"
  timeout       = 30
  publish       = true

  allowed_triggers = {
    for rule, params in local.event_rules : rule => {
      principal    = "events.amazonaws.com"
      source_arn   = aws_cloudwatch_event_rule.this[rule].arn
      statement_id = "AllowExecutionFrom${rule}"
    }
  }

  environment_variables = {
    SLACK_WEBHOOK_URL = var.slack_webhook_url
    LOG_EVENTS        = true
    LOG_LEVEL         = "INFO"
  }

  cloudwatch_logs_retention_in_days = 14

  tags = var.tags
}
