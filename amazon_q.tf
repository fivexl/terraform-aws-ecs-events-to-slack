module "chatbot_role" {
  source = "./modules/iam"
}

module "chatbot_slack_workspace" {
  count  = length(var.slack_config) > 0 ? 1 : 0
  source = "./modules/slack_workspace"

  workspace_id         = var.slack_config.workspace_id
  default_iam_role_arn = module.chatbot_role.iam_role_arn

  channels_config = {
    prod = {
      slack_channel_id = var.slack_config.channel_id
      sns_topic_arns   = [aws_sns_topic.prod_chatbot.arn]
    }
  }
}

#Testing is required for this module

module "chatbot_team_workspace" {
  count  = length(var.teams_config) > 0 ? 1 : 0
  source = "./modules/team_workspace"

  teams_tenant_id      = var.teams_config.teams_tenant_id
  default_iam_role_arn = module.chatbot_role.iam_role_arn

  channels_config = {
    prod = {
      teams_channel_id = var.teams_config.channel_id
      team_id          = var.teams_config.team_id
      sns_topic_arns   = [aws_sns_topic.prod_chatbot.arn]
    }
  }
}
#Testing is required for this module
