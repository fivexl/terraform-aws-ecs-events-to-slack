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
  version = "8.7.0"

  function_name = var.name
  role_name     = var.role_name
  create_role   = var.create_role
  lambda_role   = var.lambda_role
  description   = "Receive events from EventBridge and send them to Slack"

  package_type   = var.use_pre_created_image ? "Image" : "Zip"
  create_package = var.use_pre_created_image ? false : true
  build_in_docker = var.use_pre_created_image ? false : true
  image_uri      = var.use_pre_created_image ? "${var.ecr_owner_account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com/${var.ecr_repo_name}:${var.ecr_repo_tag}" : null
  source_path    = var.use_pre_created_image ? null : "${path.module}/functions"
  handler        = var.use_pre_created_image ? null : "slack_notifications.lambda_handler"
  runtime        = var.use_pre_created_image ? null : "python3.10"

  recreate_missing_package = var.recreate_missing_package

  timeout = 30
  publish = true

  memory_size = var.lambda_memory_size

  allowed_triggers = {
    for rule, params in local.event_rules : rule => {
      principal    = "events.amazonaws.com"
      source_arn   = aws_cloudwatch_event_rule.this[rule].arn
      statement_id = "AllowExecutionFrom${rule}"
    }
  }

  environment_variables = {
    SLACK_WEBHOOK_URL             = var.slack_webhook_url
    LOG_EVENTS                    = true
    LOG_LEVEL                     = "INFO"
    SLACK_WEBHOOK_URL_SOURCE_TYPE = var.slack_webhook_url_source_type
  }

  cloudwatch_logs_retention_in_days = var.cloudwatch_logs_retention_in_days

  attach_policy_json = (var.slack_webhook_url_source_type != "text")

  policy_json = (
    var.slack_webhook_url_source_type == "secretsmanager" ? data.aws_iam_policy_document.secretsmanager[0].json :
    var.slack_webhook_url_source_type == "ssm" ? data.aws_iam_policy_document.ssm[0].json : null
  )

  tags = var.tags
}

data "aws_iam_policy_document" "secretsmanager" {
  count = var.slack_webhook_url_source_type == "secretsmanager" ? 1 : 0
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:secret:${var.slack_webhook_url}*"]
  }
}

data "aws_iam_policy_document" "ssm" {
  count = var.slack_webhook_url_source_type == "ssm" ? 1 : 0
  statement {
    actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter${var.slack_webhook_url}*"]
  }
}
