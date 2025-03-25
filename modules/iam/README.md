# Iam for Chatbot

Automated creation of IAM resources for AWS Chatbot.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.64 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_chatbot_notifications_only_policy"></a> [chatbot\_notifications\_only\_policy](#module\_chatbot\_notifications\_only\_policy) | terraform-aws-modules/iam/aws//modules/iam-policy | 5.28.0 |
| <a name="module_chatbot_role"></a> [chatbot\_role](#module\_chatbot\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | 5.28.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_notifications_only_policy"></a> [create\_notifications\_only\_policy](#input\_create\_notifications\_only\_policy) | (Optional) Whether to create the AWS-Chatbot-NotificationsOnly-Policy policy. Defaults to true. | `bool` | `true` | no |
| <a name="input_create_role"></a> [create\_role](#input\_create\_role) | (Optional) Whether to create the AWSChatbot role. Defaults to true. | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to all resources. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | n/a |
| <a name="output_notifications_only_policy_arn"></a> [notifications\_only\_policy\_arn](#output\_notifications\_only\_policy\_arn) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
