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

resource "aws_ecr_repository" "lambda_repo" {
  name                 = "ecs-events-to-slack-repo"
  
  # REASON: UPDATED - Hardening best practice requires immutable tags to prevent 
  # attackers or bugs from overwriting valid image versions with malicious code.
  # image_tag_mutability = "MUTABLE"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = local.event_rules

  target_id = "${var.name}-${each.key}"
  arn       = module.slack_notifications.lambda_function_arn
  rule      = aws_cloudwatch_event_rule.this[each.key].name
}

# REASON FOR COMMENTING OUT: Docker build/push logic has been moved to GitHub Actions 
# (.github/workflows/build_docker.yml) to run on 'Release'. This removes the dependency 
# on the local machine's Docker daemon and credentials during 'terraform apply'.
# resource "null_resource" "docker_build_push" {
#   triggers = {
#     # Re-build if these files change
#     docker_file  = filemd5("${path.module}/functions/Dockerfile")
#     requirements = filemd5("${path.module}/functions/requirements.txt")
#     source_code  = filemd5("${path.module}/functions/slack_notifications.py")
#   }

#   provisioner "local-exec" {
#     command = <<EOF
#       aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.lambda_repo.repository_url}
#       docker build --platform linux/amd64 -t ${aws_ecr_repository.lambda_repo.repository_url}:latest -f functions/Dockerfile functions/
#       docker push ${aws_ecr_repository.lambda_repo.repository_url}:latest
#     EOF
#   }
# }

module "slack_notifications" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.0.0"

  function_name = var.name
  role_name     = var.role_name
  create_role   = var.create_role
  lambda_role   = var.lambda_role
  description   = "Receive events from EventBridge and send them to Slack"

  # --- DOCKER UPDATES ---
  create_package = false
  package_type   = "Image"
  
  # REASON: UPDATED - Switched from 'latest' to specific version variable (var.image_version).
  # This enforces manual versioning for production releases, preventing 'silent' updates
  # and allowing for controlled rollbacks (Anton's Request).
  # image_uri      = "${aws_ecr_repository.lambda_repo.repository_url}:latest"
  image_uri      = "${aws_ecr_repository.lambda_repo.repository_url}:${var.image_version}"

  # REASON: DEPRECATED - Handler, source_path, and runtime are defined in the Dockerfile 
  # or irrelevant for Image package_type.
  # handler       = "slack_notifications.lambda_handler"
  # source_path   = "${path.module}/functions/slack_notifications.py"
  # runtime       = "python3.10"
  
  # REASON: DEPRECATED - Package management is handled by Docker CI, not local Terraform.
  # recreate_missing_package = var.recreate_missing_package

  timeout = 30
  publish = true

  memory_size = var.lambda_memory_size

  # REASON FOR COMMENTING OUT: Since the image is now built in CI prior to deployment (on Release), 
  # Terraform no longer needs to wait for a local null_resource to complete.
  # depends_on = [null_resource.docker_build_push]

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
  policy_json = var.slack_webhook_url_source_type == "secretsmanager" ? jsonencode(
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
    ) : var.slack_webhook_url_source_type == "ssm" ? jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "ssm:GetParameter",
            "ssm:GetParameters",
            "ssm:GetParametersByPath",
          ],
          "Resource" : [
            "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.slack_webhook_url}*",
          ]
        }
      ]
    }
  ) : null


  tags = var.tags
}