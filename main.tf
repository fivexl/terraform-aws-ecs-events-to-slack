locals {
  # Create a result map of all built-in event rules and give custom rules.
  # If the `*_event_rule_detail` variable is set ot the empty map `{}` explicitly,
  # then the corresponding event rule will not created.
  event_rules = merge(
    length(var.ecs_task_state_event_rule_detail) == 0 ? {} : {
      ECSTaskStateChange = {
        detail-type = ["ECS Task State Change"]
        detail = var.ecs_task_state_event_rule_detail
      }
    },
    length(var.ecs_deployment_state_event_rule_detail) == 0 ? {} : {
      ECSDeploymentStateChange = {
        detail-type = ["ECS Deployment State Change"]
        detail = var.ecs_deployment_state_event_rule_detail
      }
    },
    length(var.ecs_service_action_event_rule_detail) == 0 ? {} : {
      ECSServiceAction = {
        detail-type = ["ECS Service Action"]
        detail = var.ecs_service_action_event_rule_detail
      }
    },
    var.custom_event_rules
  )
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = local.event_rules

  name_prefix = "${var.name}-${each.key}"
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
