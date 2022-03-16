resource "aws_sns_topic" "ecs_events" {
  name = "${local.project_name}-ecs-events"
  tags = local.tags
}

data "aws_iam_policy_document" "sns_ecs_events" {
  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.ecs_events.arn
    ]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_sns_topic_policy" "ecs_events" {
  arn    = aws_sns_topic.ecs_events.arn
  policy = data.aws_iam_policy_document.sns_ecs_events.json
}

resource "aws_cloudwatch_event_rule" "ecs_task" {
  name          = "${local.project_name}-ecs-task"
  event_pattern = <<EOF
{
  "source": [
    "aws.ecs"
  ],
  "detail-type": [
    "ECS Task State Change"
  ],
  "detail": {
    "clusterArn": [
      "${aws_ecs_cluster.this.arn}"
    ],
    "lastStatus": [
      "PROVISIONING",
      "PENDING",
      "ACTIVATING",
      "RUNNING",
      "DEACTIVATING",
      "STOPPED"
    ]
  }
}
EOF
  tags          = local.tags
}

resource "aws_cloudwatch_event_rule" "ecs_service" {
  name          = "${local.project_name}-ecs-service"
  event_pattern = <<EOF
{
  "source": [
    "aws.ecs"
  ],
  "detail-type": [
    "ECS Service Action"
  ],
  "detail": {
    "clusterArn": [
      "${aws_ecs_cluster.this.arn}"
    ]
  }
}
EOF
  tags          = local.tags
}

resource "aws_cloudwatch_event_rule" "ecs_deployment" {
  name          = "${local.project_name}-ecs-deployment"
  event_pattern = <<EOF
{
  "source": [
    "aws.ecs"
  ],
  "detail-type": [
    "ECS Deployment State Change"
  ]
}
EOF
  tags          = local.tags
}

resource "aws_cloudwatch_event_target" "ecs_task" {
  target_id = "${local.project_name}-${aws_sns_topic.ecs_events.name}-task"
  arn       = aws_sns_topic.ecs_events.arn
  rule      = aws_cloudwatch_event_rule.ecs_task.name
}

resource "aws_cloudwatch_event_target" "ecs_service" {
  target_id = "${local.project_name}-${aws_sns_topic.ecs_events.name}-service"
  arn       = aws_sns_topic.ecs_events.arn
  rule      = aws_cloudwatch_event_rule.ecs_service.name
}

resource "aws_cloudwatch_event_target" "ecs_deployment" {
  target_id = "${local.project_name}-${aws_sns_topic.ecs_events.name}-deployment"
  arn       = aws_sns_topic.ecs_events.arn
  rule      = aws_cloudwatch_event_rule.ecs_deployment.name
}


module "slack_notifications" {
  source                            = "terraform-aws-modules/lambda/aws"
  version                           = "1.44.0"
  function_name                     = "${local.project_name}-slack-notifications"
  description                       = "Used to receive events from EventBridge via SNS and send them to Slack"
  handler                           = "slack_notifications.lambda_handler"
  source_path                       = "${path.module}/functions/slack_notifications.py"
  runtime                           = "python3.8"
  timeout                           = 30
  publish                           = true
  cloudwatch_logs_retention_in_days = 14
  allowed_triggers = {
    AllowExecutionFromSNS = {
      principal  = "sns.amazonaws.com"
      source_arn = aws_sns_topic.ecs_events.arn
    }
  }
  environment_variables = {
    HOOK_URL   = jsondecode(data.aws_secretsmanager_secret_version.external_secrets.secret_string)["slack_webhook_url"]
    LOG_EVENTS = "True"
  }
  tags = local.tags
}

resource "aws_sns_topic_subscription" "sns_notify_slack" {
  topic_arn = aws_sns_topic.ecs_events.arn
  protocol  = "lambda"
  endpoint  = module.slack_notifications.this_lambda_function_arn
}
