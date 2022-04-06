provider "aws" {
  region = "us-east-1"
}

data "aws_ecs_cluster" "this" {
  cluster_name = "EXAMPLE-CLUSTER-NAME"
}

module "ecs_to_slack" {
  source            = "../../"
  name              = "ecs-to-slack"
  slack_webhook_url = "https://hooks.slack.com/YOUR-WEBHOOK-ID"

  # Do not create any built-in rule
  ecs_task_state_event_rule_detail       = {}
  ecs_deployment_state_event_rule_detail = {}
  ecs_service_action_event_rule_detail   = {}

  # Create a custom rule, for all events from the cluster's Container Instances
  custom_event_rules = {
    ECSContInstanceStateChange = {
      detail-type = ["ECS Container Instance State Change"]
      detail = {
        clusterArn = [data.aws_ecs_cluster.this.arn], # Filter by this ECS cluster ARN,
        status     = [{ "anything-but" = "ACTIVE" }]  # except events with status = ACTIVE
      }
    }
  }
}
