resource "awscc_chatbot_slack_channel_configuration" "this" {
  for_each = var.channels_config

  slack_workspace_id = var.workspace_id

  configuration_name = each.value.slack_channel_id
  slack_channel_id   = each.value.slack_channel_id

  iam_role_arn       = coalesce(each.value.iam_role_arn, var.default_iam_role_arn)
  sns_topic_arns     = coalesce(each.value.sns_topic_arns, var.default_sns_topic_arns)
  guardrail_policies = coalesce(each.value.guardrail_policies, var.default_guardrail_policies)
  logging_level      = coalesce(each.value.logging_level, var.default_logging_level)
  user_role_required = coalesce(each.value.user_role_required, var.default_user_role_required)
}
