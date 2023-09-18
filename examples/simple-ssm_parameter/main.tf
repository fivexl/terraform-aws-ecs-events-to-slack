provider "aws" {
  region = "us-east-1"
}

module "ecs_to_slack" {
  source = "../../"
  name   = "ecs-to-slack"

  # Use the ssm parameter name instead of the plaintext hook url. Must contain the initial slash "/"!
  slack_webhook_url = "/ecs_to_slack/hook/dev"


  # Required to allow ssm lookups.
  slack_webhook_url_source_type = "ssm" 

  # We do not override any built-in event rules, so the default values will be used
}
