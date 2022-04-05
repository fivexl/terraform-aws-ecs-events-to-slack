provider "aws" {
  region = "us-east-1"
}

module "ecs_to_slack_notifications" {
  source            = "../../"
  name              = "ecs-to-eb"
  slack_webhook_url = "https://hooks.slack.com/YOUR-WEBHOOK-ID"

  # We do not override any built-in event rules, so the default values will be used
}
