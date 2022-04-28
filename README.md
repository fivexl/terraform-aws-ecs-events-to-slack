[![FivexL](https://releases.fivexl.io/fivexlbannergit.jpg)](https://fivexl.io/)

# terraform-aws-ecs-events-to-slack
Rules for Amazon EventBridge that fetch ECS events and send them to Slack

## Example
```hcl
module "ecs_to_slack" {
  source            = "git::https://github.com/fivexl/terraform-aws-ecs-events-to-slack.git"
  name              = "ecs-to-slack"
  slack_webhook_url = "https://hooks.slack.com/YOUR-WEBHOOK-ID"
}
```
You can find more examples in the [`examples/`](./examples/) directory

## Info
- [Amazon ECS events](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwe_events.html)
- [Handling events with Lambda](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_cwet_handling.html)
- [EventBridge Patterns](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-event-patterns.html)

## AWS Terraform provier versions

* version 0.1.2 is the last version that works with both Terraform AWS provider v3 and v4. There are no plans to update 0.1.X branch.
* all versions later (0.2.0 and above) require Terraform AWS provider v4 as a baseline

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.69 |
| <a name="requirement_external"></a> [external](#requirement\_external) | >= 1.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 1.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.69 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_slack_notifications"></a> [slack\_notifications](#module\_slack\_notifications) | terraform-aws-modules/lambda/aws | 3.2.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_event_rules"></a> [custom\_event\_rules](#input\_custom\_event\_rules) | A map of objects representing the custom EventBridge rule which will be created in addition to the default rules. | <pre>map(object({<br>    detail-type = any<br>    detail      = any<br>  }))</pre> | `{}` | no |
| <a name="input_ecs_deployment_state_event_rule_detail"></a> [ecs\_deployment\_state\_event\_rule\_detail](#input\_ecs\_deployment\_state\_event\_rule\_detail) | The content of the `detail` section in the EvenBridge Rule for `ECS Deployment State Change` events. Use it to filter the events which will be processed and sent to Slack. | `any` | <pre>{<br>  "eventType": [<br>    "ERROR"<br>  ]<br>}</pre> | no |
| <a name="input_ecs_service_action_event_rule_detail"></a> [ecs\_service\_action\_event\_rule\_detail](#input\_ecs\_service\_action\_event\_rule\_detail) | The content of the `detail` section in the EvenBridge Rule for `ECS Service Action` events. Use it to filter the events which will be processed and sent to Slack. | `any` | <pre>{<br>  "eventType": [<br>    "WARN",<br>    "ERROR"<br>  ]<br>}</pre> | no |
| <a name="input_ecs_task_state_event_rule_detail"></a> [ecs\_task\_state\_event\_rule\_detail](#input\_ecs\_task\_state\_event\_rule\_detail) | The content of the `detail` section in the EvenBridge Rule for `ECS Task State Change` events. Use it to filter the events which will be processed and sent to Slack. | `any` | <pre>{<br>  "lastStatus": [<br>    "STOPPED"<br>  ],<br>  "stoppedReason": [<br>    {<br>      "anything-but": {<br>        "prefix": "Scaling activity initiated by (deployment ecs-svc/"<br>      }<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_enable_ecs_deployment_state_event_rule"></a> [enable\_ecs\_deployment\_state\_event\_rule](#input\_enable\_ecs\_deployment\_state\_event\_rule) | The boolean flag enabling the EvenBridge Rule for `ECS Deployment State Change` events. The `detail` section of this rule is configured with `ecs_deployment_state_event_rule_detail` variable. | `bool` | `true` | no |
| <a name="input_enable_ecs_service_action_event_rule"></a> [enable\_ecs\_service\_action\_event\_rule](#input\_enable\_ecs\_service\_action\_event\_rule) | The boolean flag enabling the EvenBridge Rule for `ECS Service Action` events. The `detail` section of this rule is configured with `ecs_service_action_event_rule_detail` variable. | `bool` | `true` | no |
| <a name="input_enable_ecs_task_state_event_rule"></a> [enable\_ecs\_task\_state\_event\_rule](#input\_enable\_ecs\_task\_state\_event\_rule) | The boolean flag enabling the EvenBridge Rule for `ECS Task State Change` events. The `detail` section of this rule is configured with `ecs_task_state_event_rule_detail` variable. | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | The string which will be used for the name of AWS Lambda function and other creaated resources | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | The string which will be used for the name of Lambda IAM role | `string` | `null` | no |
| <a name="input_slack_webhook_url"></a> [slack\_webhook\_url](#input\_slack\_webhook\_url) | Slack incoming webhook URL | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
