provider "aws" {
  region = "us-east-1"
}

data "aws_ecs_cluster" "this" {
  cluster_name = "EXAMPLE-CLUSTER-NAME"
}

module "ecs_to_slack" {
  source            = "../terraform-aws-ecs-events-to-slack"
  name              = "amazon_q_notifications"
  

  # Do not create any built-in rule
  ecs_task_state_event_rule_detail       = {}
  ecs_deployment_state_event_rule_detail = {}
  ecs_service_action_event_rule_detail   = {}

  # Create a custom rule, for all events from the cluster's Container Instances
  # Find more infro here https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns-content-based-filtering.html
  custom_event_rules = {
    ECSContInstanceStateChange = {
      detail-type = ["ECS Container Instance State Change"]
      detail = {
        clusterArn = [data.aws_ecs_cluster.this.arn], # Filter by this ECS cluster ARN,
        status     = [{ "anything-but" = "ACTIVE" }]  # except events with status = ACTIVE
      }
    }
  slack_config = {
    channel_id   = "1234567890"  # Your Slack workspace ID
    workspace_id = "1234567890"   # Your Slack channel ID
  }
  #Testing is required for teams
  # teams_config = {
  #   team_id         = "1234567890" # Your Teams id ID
  #   channel_id      = "1234567890" # Your Teams channel ID
  #   teams_tenant_id = "1234567890" # Your Teams tenant ID
  # }
  }
}
