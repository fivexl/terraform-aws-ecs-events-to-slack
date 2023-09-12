locals {
  # Create a result map of all built-in event rules and given custom rules.
  event_rules = merge(
    var.enable_ecs_task_state_event_rule ? {
      ECSTaskStateChange = {
        detail-type = ["ECS Task State Change"]
        detail      = var.ecs_task_state_event_rule_detail
      }
    } : {},
    var.enable_ecs_deployment_state_event_rule ? {
      ECSDeploymentStateChange = {
        detail-type = ["ECS Deployment State Change"]
        detail      = var.ecs_deployment_state_event_rule_detail
      }
    } : {},
    var.enable_ecs_service_action_event_rule ? {
      ECSServiceAction = {
        detail-type = ["ECS Service Action"]
        detail      = var.ecs_service_action_event_rule_detail
      }
    } : {},
    var.custom_event_rules
  )
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = local.event_rules

  name = "${var.name}-${each.key}"
  event_pattern = jsonencode({
    source      = [try(each.value.source, "aws.ecs")]
    detail-type = each.value.detail-type
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
  version = "5.0.0"

  function_name = var.name
  role_name     = var.role_name
  description   = "Receive events from EventBridge and send them to Slack"
  handler       = "slack_notifications.lambda_handler"
  source_path   = "${path.module}/functions/slack_notifications.py"
  runtime       = "python3.10"
  timeout       = 30
  publish       = true

  memory_size = var.lambda_memory_size

  recreate_missing_package = var.recreate_missing_package

  allowed_triggers = {
    for rule, params in local.event_rules : rule => {
      principal    = "events.amazonaws.com"
      source_arn   = aws_cloudwatch_event_rule.this[rule].arn
      statement_id = "AllowExecutionFrom${rule}"
    }
  }

  environment_variables = {
    SLACK_WEBHOOK_URL                       = var.slack_webhook_url
    LOG_EVENTS                              = true
    LOG_LEVEL                               = "INFO"
    SLACK_WEBHOOK_URL_SECRETSMANAGER_LOOKUP = var.slack_webhook_url_secretsmanager_lookup
  }

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  attach_policy_json = var.slack_webhook_url_secretsmanager_lookup
  policy_json = var.slack_webhook_url_secretsmanager_lookup ? jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "secretsmanager:GetSecretValue",
          ],
          "Resource" : [
            "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.slack_webhook_url}*",
          ]
        }
      ]
    }
  ) : null

  tags = var.tags
}
