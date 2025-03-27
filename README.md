[![FivexL](https://releases.fivexl.io/fivexlbannergit.jpg)](https://fivexl.io/)

# terraform-aws-ecs-events-to-slack
Rules for Amazon EventBridge that fetch ECS events and send them to Slack, Teams and Chime

# AWS Chatbot Integration for Slack, Teams, and Chime

This module provides integration between AWS services and various chat platforms (Slack, Microsoft Teams, and Amazon Chime) using AWS Chatbot.

## Features

- Support for multiple chat platforms:
  - Slack (fully tested and supported)
  - Microsoft Teams (requires paid Microsoft 365 account, configuration not fully tested)
  - Amazon Chime (no Terraform configuration available yet) 

## Prerequisites

- Slack workspace (for Slack integration)
- Microsoft Teams (for Teams integration)



### Setting Up AWS Q in Slack

Before deploying this module, you must set up the Slack workspace. Follow the steps below or consult the official documentation.

1. In Slack's left navigation pane, select Apps.
   - Note: If Apps isn't visible, click on More, then choose Apps.
2. If AWS Q isn't listed, click on Browse Apps Directory (or try searching for AWS Chatbot).
3. Search for the AWS Q app and click Add to integrate it into your workspace.
4. Navigate to the AWS Q console.
5. Under "Configure a chat client", select Slack, then Configure client.
6. From the dropdown list, choose the Slack workspace you wish to use with AWS Q.
7. Click Allow.
8. The module will handle the rest - just provide it with the workspace ID and channel you want to use, and it will create the configuration.

### Setting Up Amazon Chime

Amazon Chime doesn't have Terraform configuration available yet, so it needs to be set up manually:

1. Deploy the module and get the SNS topic ARN
2. Go to the AWS Console and use the acquired SNS topic to create a topic -> Channel configuration
3. Follow this guide: [Amazon Chime Setup Guide](https://docs.aws.amazon.com/chatbot/latest/adminguide/chime-setup.html#chime-sets)

### Setting Up Microsoft Teams

This part of the module hasn't been tested because Microsoft Teams requires a paid plan to use bot features. Please be aware that some issues might occur.

1. Follow the first step from this guide to set up the client: [Microsoft Teams Setup Guide](https://docs.aws.amazon.com/chatbot/latest/adminguide/teams-setup.html)
2. Theoretically, by providing the following configuration, the module should handle everything else, but as stated above, it hasn't been tested:

```hcl
teams_config = {
  team_id         = "YOUR_TEAMS_ID"
  channel_id      = "YOUR_TEAMS_CHANNEL_ID"
  teams_tenant_id = "YOUR_TEAMS_TENANT_ID"
}
```
## Example
```hcl
module "ecs_to_slack" {
  source            = "git::https://github.com/fivexl/terraform-aws-ecs-events-to-slack.git"
  name              = "amazon_q_notifications"

  # Enable ECS task state change events
  enable_ecs_task_state_event_rule = true
  ecs_task_state_event_rule_detail = {
    clusterArn = ["arn:aws:ecs:us-east-1:123333333333:cluster/your-cluster-name"]
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

```
You can find more examples in the [`examples/`](./examples/) directory

## Info
- [Amazon ECS events](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwe_events.html)
- [Handling events with Lambda](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwet_handling.html)
- [EventBridge Patterns](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html)
- [Amazon_q custom-notifs](https://docs.aws.amazon.com/chatbot/latest/adminguide/custom-notifs.html)

## AWS Terraform provier versions

* version 0.1.2 is the last version that works with both Terraform AWS provider v3 and v4. There are no plans to update 0.1.X branch.
* all versions later (0.2.0 and above) require Terraform AWS provider v4 as a baseline

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name                                                                      | Version   |
| ------------------------------------------------------------------------- | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws)                   | >= 3.69   |

## Providers

| Name                                              | Version |
| ------------------------------------------------- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.69 |

## Modules

| Name                                                                                            | Source                           | Version |
| ----------------------------------------------------------------------------------------------- | -------------------------------- | ------- |
| <a name="module_slack_notifications"></a> [slack\_notifications](#module\_slack\_notifications) | terraform-aws-modules/lambda/aws | 5.0.0   |

## Resources

| Name                                                                                                                                                                                    | Type        |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule)                                                     | resource    |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target)                                                 | resource    |
| [aws_sns_topic.prod_chatbot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic)                                                                     | resource    |
| [aws_sns_topic_policy.prod_chatbot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy)                                                       | resource    |
| [awscc_chatbot_slack_channel_configuration.this](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/chatbot_slack_channel_configuration)                     | resource    |
| [awscc_chatbot_microsoft_teams_channel_configuration.this](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/chatbot_microsoft_teams_channel_configuration) | resource    |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                                                           | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                                                             | data source |

## Inputs

| Name                                                                                                                                                           | Description                                                                                                                                                                                     | Type     | Default                                                                                                                                                                                                                          | Required |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_cloudwatch_logs_retention_in_days"></a> [cloudwatch\_logs\_retention\_in\_days](#input\_cloudwatch\_logs\_retention\_in\_days)                  | Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653.      | `number` | `14`                                                                                                                                                                                                                             |    no    |
| <a name="input_custom_event_rules"></a> [custom\_event\_rules](#input\_custom\_event\_rules)                                                                   | A map of objects representing the custom EventBridge rule which will be created in addition to the default rules.                                                                               | `any`    | `{}`                                                                                                                                                                                                                             |    no    |
| <a name="input_ecs_deployment_state_event_rule_detail"></a> [ecs\_deployment\_state\_event\_rule\_detail](#input\_ecs\_deployment\_state\_event\_rule\_detail) | The content of the `detail` section in the EvenBridge Rule for `ECS Deployment State Change` events. Use it to filter the events which will be processed and sent to Slack.                     | `any`    | <pre>{<br>  "eventType": [<br>    "ERROR"<br>  ]<br>}</pre>                                                                                                                                                                      |    no    |
| <a name="input_ecs_service_action_event_rule_detail"></a> [ecs\_service\_action\_event\_rule\_detail](#input\_ecs\_service\_action\_event\_rule\_detail)       | The content of the `detail` section in the EvenBridge Rule for `ECS Service Action` events. Use it to filter the events which will be processed and sent to Slack.                              | `any`    | <pre>{<br>  "eventType": [<br>    "WARN",<br>    "ERROR"<br>  ]<br>}</pre>                                                                                                                                                       |    no    |
| <a name="input_ecs_task_state_event_rule_detail"></a> [ecs\_task\_state\_event\_rule\_detail](#input\_ecs\_task\_state\_event\_rule\_detail)                   | The content of the `detail` section in the EvenBridge Rule for `ECS Task State Change` events. Use it to filter the events which will be processed and sent to Slack.                           | `any`    | <pre>{<br>  "lastStatus": [<br>    "STOPPED"<br>  ],<br>  "stoppedReason": [<br>    {<br>      "anything-but": {<br>        "prefix": "Scaling activity initiated by (deployment ecs-svc/"<br>      }<br>    }<br>  ]<br>}</pre> |    no    |
| <a name="input_enable_ecs_deployment_state_event_rule"></a> [enable\_ecs\_deployment\_state\_event\_rule](#input\_enable\_ecs\_deployment\_state\_event\_rule) | The boolean flag enabling the EvenBridge Rule for `ECS Deployment State Change` events. The `detail` section of this rule is configured with `ecs_deployment_state_event_rule_detail` variable. | `bool`   | `true`                                                                                                                                                                                                                           |    no    |
| <a name="input_enable_ecs_service_action_event_rule"></a> [enable\_ecs\_service\_action\_event\_rule](#input\_enable\_ecs\_service\_action\_event\_rule)       | The boolean flag enabling the EvenBridge Rule for `ECS Service Action` events. The `detail` section of this rule is configured with `ecs_service_action_event_rule_detail` variable.            | `bool`   | `true`                                                                                                                                                                                                                           |    no    |
