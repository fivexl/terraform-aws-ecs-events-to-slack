[![FivexL](https://releases.fivexl.io/fivexlbannergit_new.png)](https://fivexl.io/#email-subscription)

### Want practical AWS infrastructure insights?

👉 [Subscribe to our newsletter](https://fivexl.io/#email-subscription) to get:

- Real stories from real AWS projects  
- No-nonsense DevOps tactics  
- Cost, security & compliance patterns that actually work  
- Expert guidance from engineers in the field

=========================================================================

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

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.69 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_slack_notifications"></a> [slack\_notifications](#module\_slack\_notifications) | terraform-aws-modules/lambda/aws | 5.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_logs_retention_in_days"></a> [cloudwatch\_logs\_retention\_in\_days](#input\_cloudwatch\_logs\_retention\_in\_days) | Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653. | `number` | `14` | no |
| <a name="input_custom_event_rules"></a> [custom\_event\_rules](#input\_custom\_event\_rules) | A map of objects representing the custom EventBridge rule which will be created in addition to the default rules. | `any` | `{}` | no |
| <a name="input_ecs_deployment_state_event_rule_detail"></a> [ecs\_deployment\_state\_event\_rule\_detail](#input\_ecs\_deployment\_state\_event\_rule\_detail) | The content of the `detail` section in the EvenBridge Rule for `ECS Deployment State Change` events. Use it to filter the events which will be processed and sent to Slack. | `any` | <pre>{<br>  "eventType": [<br>    "ERROR"<br>  ]<br>}</pre> | no |
| <a name="input_ecs_service_action_event_rule_detail"></a> [ecs\_service\_action\_event\_rule\_detail](#input\_ecs\_service\_action\_event\_rule\_detail) | The content of the `detail` section in the EvenBridge Rule for `ECS Service Action` events. Use it to filter the events which will be processed and sent to Slack. | `any` | <pre>{<br>  "eventType": [<br>    "WARN",<br>    "ERROR"<br>  ]<br>}</pre> | no |
| <a name="input_ecs_task_state_event_rule_detail"></a> [ecs\_task\_state\_event\_rule\_detail](#input\_ecs\_task\_state\_event\_rule\_detail) | The content of the `detail` section in the EvenBridge Rule for `ECS Task State Change` events. Use it to filter the events which will be processed and sent to Slack. | `any` | <pre>{<br>  "lastStatus": [<br>    "STOPPED"<br>  ],<br>  "stoppedReason": [<br>    {<br>      "anything-but": {<br>        "prefix": "Scaling activity initiated by (deployment ecs-svc/"<br>      }<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_enable_ecs_deployment_state_event_rule"></a> [enable\_ecs\_deployment\_state\_event\_rule](#input\_enable\_ecs\_deployment\_state\_event\_rule) | The boolean flag enabling the EvenBridge Rule for `ECS Deployment State Change` events. The `detail` section of this rule is configured with `ecs_deployment_state_event_rule_detail` variable. | `bool` | `true` | no |
| <a name="input_enable_ecs_service_action_event_rule"></a> [enable\_ecs\_service\_action\_event\_rule](#input\_enable\_ecs\_service\_action\_event\_rule) | The boolean flag enabling the EvenBridge Rule for `ECS Service Action` events. The `detail` section of this rule is configured with `ecs_service_action_event_rule_detail` variable. | `bool` | `true` | no |
| <a name="input_enable_ecs_task_state_event_rule"></a> [enable\_ecs\_task\_state\_event\_rule](#input\_enable\_ecs\_task\_state\_event\_rule) | The boolean flag enabling the EvenBridge Rule for `ECS Task State Change` events. The `detail` section of this rule is configured with `ecs_task_state_event_rule_detail` variable. | `bool` | `true` | no |
| <a name="input_lambda_memory_size"></a> [lambda\_memory\_size](#input\_lambda\_memory\_size) | Amount of memory in MB your Lambda Function can use at runtime. Valid value between 128 MB to 10,240 MB (10 GB), in 64 MB increments. | `number` | `256` | no |
| <a name="input_name"></a> [name](#input\_name) | The string which will be used for the name of AWS Lambda function and other creaated resources | `string` | n/a | yes |
| <a name="input_recreate_missing_package"></a> [recreate\_missing\_package](#input\_recreate\_missing\_package) | Whether to recreate missing Lambda package if it is missing locally or not. | `bool` | `true` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | The string which will be used for the name of Lambda IAM role | `string` | `null` | no |
| <a name="input_slack_webhook_url"></a> [slack\_webhook\_url](#input\_slack\_webhook\_url) | (default) A Slack incoming webhook URL. (if slack\_webhook\_url\_source\_type is 'secret') A secretsmanager secret name. | `string` | n/a | yes |
| <a name="input_slack_webhook_url_source_type"></a> [slack\_webhook\_url\_source\_type](#input\_slack\_webhook\_url\_source\_type) | Define where to get the slack webhook URL for variable slack\_webhook\_url. Either as text input or from an AWS secretsmanager lookup | `string` | `"text"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Post review
- Post review [url](https://github.com/fivexl/terraform-aws-ecs-events-to-slack/compare/review...main)
