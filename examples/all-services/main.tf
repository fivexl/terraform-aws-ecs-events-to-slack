provider "aws" {
  region = "us-east-1"
}

data "aws_ecs_cluster" "this" {
  cluster_name = "EXAMPLE-CLUSTER-NAME"
}

module "ecs_to_slack_notifications" {
  source            = "../../"
  name              = "ecs-to-eb"
  slack_webhook_url = "https://hooks.slack.com/YOUR-WEBHOOK-ID"

  event_rules = {
    # Process events "ECS Task State Change" from the given cluster when task is stopped
    ECSTaskStateChange = {
      detail = {
        clusterArn = [data.aws_ecs_cluster.this.arn],
        lastStatus = ["STOPPED"]
        stopCode   = [{ "anything-but" = "EssentialContainerExited" }] # Ignore this stopCode
      }
    }

    # Skip all events "ECS Deployment State Change"
    ECSDeploymentStateChange = {}

    # Process all events "ECS Service Action" from the given cluster
    ECSServiceAction = {
      detail = {
        clusterArn = [data.aws_ecs_cluster.this.arn],
        eventName  = [{ "anything-but" = "SERVICE_TASK_START_IMPAIRED" }] # Ignore this eventName
      }
    }
  }
}
