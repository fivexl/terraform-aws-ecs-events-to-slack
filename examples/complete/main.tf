# AWS Provider Configuration
provider "aws" {
  region = "us-east-1"
}

module "ecs_to_slack" {
  source = "../terraform-aws-ecs-events-to-slack"
  name   = "amazon_q_notifications"

  # Enable ECS task state change events
  enable_ecs_task_state_event_rule = true
  ecs_task_state_event_rule_detail = {
    clusterArn = ["arn:aws:ecs:us-east-1:123333333333:cluster/your-cluster-name"]
  }
  slack_config = {
    channel_id   = "1234567890"  # Your Slack workspace ID
    workspace_id = "1234567890"   # Your Slack channel ID
  }
  # teams_config = {
  #   team_id         = "1234567890" # Your Teams id ID
  #   channel_id      = "1234567890" # Your Teams channel ID
  #   teams_tenant_id = "1234567890" # Your Teams tenant ID
  # }
}



