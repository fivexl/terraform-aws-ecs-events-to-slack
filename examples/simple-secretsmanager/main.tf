provider "aws" {
  region = "us-east-1"
}

module "ecs_to_slack" {
  source            = "../../"
  name              = "ecs-to-slack"
  
  # Use the secretsmanager secret name instead or the plaintext hook url. This must exist prior to apply!
  slack_webhook_url = "/org/dev/slack_webhook_url"
  # Required to allow secretsmanager lookups.
  slack_webhook_url_secretsmanager_lookup = true

  # We do not override any built-in event rules, so the default values will be used
}
