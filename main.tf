
# "detail": {
#   "clusterArn": [
#     "${data.aws_ecs_cluster.this.arn}"
#   ],
#   "lastStatus": [
#     "STOPPED"
#   ]
# }
resource "aws_cloudwatch_event_rule" "ecs_task" {
  name_prefix   = "${var.name}-ecs-task-state"
  event_pattern = <<-EOF
    {
      "source": [
        "aws.ecs"
      ],
      "detail-type": [
        "ECS Task State Change"
      ],
      "detail": ${jsonencode(var.ecs_task_state_event_rule_detail)}
    }
  EOF

  tags = var.tags
}

# "detail": {
#   "eventType": [
#     "ERROR"
#   ]
# }
resource "aws_cloudwatch_event_rule" "ecs_deployment" {
  name_prefix   = "${var.name}-ecs-deployment-state"
  event_pattern = <<-EOF
    {
      "source": [
        "aws.ecs"
      ],
      "detail-type": [
        "ECS Deployment State Change"
      ],
      "detail": ${jsonencode(var.ecs_deployment_state_event_rule_detail)}
    }
  EOF

  tags = var.tags
}

# "detail": {
#   "clusterArn": [
#     "${data.aws_ecs_cluster.this.arn}"
#   ],
#   "eventType": [
#     "WARN",
#     "ERROR"
#   ]
# }
resource "aws_cloudwatch_event_rule" "ecs_service" {
  name_prefix   = "${var.name}-ecs-service-action"
  event_pattern = <<-EOF
    {
      "source": [
        "aws.ecs"
      ],
      "detail-type": [
        "ECS Service Action"
      ],
      "detail": ${jsonencode(var.ecs_service_action_event_rule_detail)}
    }
  EOF

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "ecs_task" {
  target_id = "${var.name}-ecs-task-state"
  arn       = module.slack_notifications.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.ecs_task.name
}

resource "aws_cloudwatch_event_target" "ecs_deployment" {
  target_id = "${var.name}-ecs-deployment-state"
  arn       = module.slack_notifications.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.ecs_deployment.name
}

resource "aws_cloudwatch_event_target" "ecs_service" {
  target_id = "${var.name}-ecs-service-action"
  arn       = module.slack_notifications.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.ecs_service.name
}


module "slack_notifications" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "3.1.0"

  function_name                     = var.name
  description                       = "Receive events from EventBridge and send them to Slack"
  handler                           = "slack_notifications.lambda_handler"
  source_path                       = "${path.module}/functions/slack_notifications.py"
  runtime                           = "python3.9"
  timeout                           = 30
  publish                           = true
  cloudwatch_logs_retention_in_days = 14
  allowed_triggers = {
    ECSTaskStateChange = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.ecs_task.arn
    }
    ECSDeploymentStateChange = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.ecs_deployment.arn
    }
    ECSServiceAction = {
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.ecs_service.arn
    }
  }
  environment_variables = {
    SLACK_WEBHOOK_URL = var.slack_webhook_url
    LOG_EVENTS        = true
    LOG_LEVEL         = "INFO"
  }
  tags = var.tags
}
