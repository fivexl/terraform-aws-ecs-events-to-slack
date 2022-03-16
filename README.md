# terraform-aws-ecs-events-to-slack
Rules for Amazon EventBridge that fetch ECS events and send that events to Slack

## Example
```hcl
module "ecs_to_slack" {
  source                    = "./ecs_to_slack"
  ecs_cluster_name          = var.ecs_cluster_name
  slack_hook_url            = var.slack_hook_url
  skip_task_stop_codes      = []
  skip_task_stopped_reasons = ["deployment"]
  tags                      = var.tags
}
```