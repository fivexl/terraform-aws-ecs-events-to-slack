output "notifications_only_policy_arn" {
  value = module.chatbot_notifications_only_policy.arn
}

output "iam_role_arn" {
  value = module.chatbot_role.iam_role_arn
}
