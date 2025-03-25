# Slack workspace configuration

This module gives you a better way to configure your Slack workspace with AWS Chatbot. It allows you to configure multiple channels and SNS topics, as well as IAM roles and logging levels.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.64 |
| <a name="requirement_awscc"></a> [awscc](#requirement\_awscc) | >= 0.57.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_awscc"></a> [awscc](#provider\_awscc) | 1.20.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [awscc_chatbot_slack_channel_configuration.this](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/chatbot_slack_channel_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_channels_config"></a> [channels\_config](#input\_channels\_config) | (Required) The list of Slack channel configurations. Each configuration block supports fields documented below.<br/><br/>    configuration\_name - (Required) The name of the configuration<br/>    iam\_role\_arn - (Required) The ARN of the IAM role that defines the permissions for AWS Chatbot<br/>    slack\_channel\_id - (Required) The id of the Slack channel<br/>    sns\_topic\_arns - (Optional) ARNs of SNS topics which delivers notifications to AWS Chatbot, for example CloudWatch alarm notifications.<br/>    guardrail\_policies - (Optional) The list of IAM policy ARNs that are applied as channel guardrails. The AWS managed 'AdministratorAccess' policy is applied as a default if this is not set.<br/>    logging\_level - (Optional) Specifies the logging level for this configuration:ERROR,INFO or NONE. This property affects the log entries pushed to Amazon CloudWatch logs<br/>    user\_role\_required - (Optional) Enables use of a user role requirement in your chat configuration | <pre>map(<br/>    object({<br/>      configuration_name = optional(string)<br/>      iam_role_arn       = optional(string)<br/>      slack_channel_id   = string<br/>      sns_topic_arns     = list(string)<br/>      guardrail_policies = optional(list(string))<br/>      logging_level      = optional(string)<br/>      user_role_required = optional(bool)<br/>    })<br/>  )</pre> | n/a | yes |
| <a name="input_default_guardrail_policies"></a> [default\_guardrail\_policies](#input\_default\_guardrail\_policies) | Default guardrail policies to apply to all channels | `list(string)` | <pre>[<br/>  "arn:aws:iam::aws:policy/ReadOnlyAccess"<br/>]</pre> | no |
| <a name="input_default_iam_role_arn"></a> [default\_iam\_role\_arn](#input\_default\_iam\_role\_arn) | Default IAM role to apply to all channels | `string` | `""` | no |
| <a name="input_default_logging_level"></a> [default\_logging\_level](#input\_default\_logging\_level) | Default logging level to apply to all channels | `string` | `"NONE"` | no |
| <a name="input_default_sns_topic_arns"></a> [default\_sns\_topic\_arns](#input\_default\_sns\_topic\_arns) | Default SNS topic ARNs to apply to all channels | `list(string)` | `[]` | no |
| <a name="input_default_user_role_required"></a> [default\_user\_role\_required](#input\_default\_user\_role\_required) | Default user role required to apply to all channels | `bool` | `false` | no |
| <a name="input_workspace_id"></a> [workspace\_id](#input\_workspace\_id) | (Required) The id of the Slack workspace | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
