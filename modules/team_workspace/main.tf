
#Testing is required for this module
resource "awscc_chatbot_microsoft_teams_channel_configuration" "this" {
  for_each = var.channels_config

  teams_tenant_id    = var.teams_tenant_id
  team_id            = each.value.team_id
  configuration_name = each.value.teams_channel_id
  teams_channel_id   = each.value.teams_channel_id

  iam_role_arn       = coalesce(each.value.iam_role_arn, var.default_iam_role_arn)
  sns_topic_arns     = coalesce(each.value.sns_topic_arns, var.default_sns_topic_arns)
  guardrail_policies = coalesce(each.value.guardrail_policies, var.default_guardrail_policies)
  logging_level      = coalesce(each.value.logging_level, var.default_logging_level)
  user_role_required = coalesce(each.value.user_role_required, var.default_user_role_required)
}
#Testing is required for this module
