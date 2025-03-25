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
  arn       = module.amazon_q_notifications.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.this[each.key].name
}

module "amazon_q_notifications" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.0.0"

  function_name = var.name
  role_name     = var.role_name
  create_role   = var.create_role
  lambda_role   = var.lambda_role
  description   = "Receive events from EventBridge and send them to Amazon Q"
  handler       = "amazon_q_notifications.lambda_handler"
  source_path   = "${path.module}/functions/amazon_q_notifications.py"
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

  # Add IAM policy for SNS publish
  attach_policy_jsons = true
  policy_jsons = [jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [aws_sns_topic.prod_chatbot.arn]
      }
    ]
  })]

  environment_variables = {
    LOG_EVENTS    = true
    LOG_LEVEL     = "INFO"
    SNS_TOPIC_ARN = aws_sns_topic.prod_chatbot.arn
  }
  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days
  tags                              = var.tags
}



