provider "aws" {
  region = "us-east-1"
}

module "ecs_to_slack" {
  source            = "../../"
  name              = "ecs-to-slack"
  
  # Use the secretsmanager secret name instead or the plaintext hook url. This must exist prior to apply!
  slack_webhook_url_source = "/org/dev/slack_webhook_url_source"
  # Required to allow secretsmanager lookups.
  slack_webhook_url_source_type = true

  # We do not override any built-in event rules, so the default values will be used
}
