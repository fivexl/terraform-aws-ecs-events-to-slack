variable "workspace_id" {
  description = "(Required) The id of the Slack workspace"
  type        = string
}

variable "channels_config" {
  type = map(
    object({
      configuration_name = optional(string)
      iam_role_arn       = optional(string)
      slack_channel_id   = string
      sns_topic_arns     = list(string)
      guardrail_policies = optional(list(string))
      logging_level      = optional(string)
      user_role_required = optional(bool)
    })
  )
  description = <<EOT
    (Required) The list of Slack channel configurations. Each configuration block supports fields documented below.

    configuration_name - (Required) The name of the configuration
    iam_role_arn - (Required) The ARN of the IAM role that defines the permissions for AWS Chatbot
    slack_channel_id - (Required) The id of the Slack channel
    sns_topic_arns - (Optional) ARNs of SNS topics which delivers notifications to AWS Chatbot, for example CloudWatch alarm notifications.
    guardrail_policies - (Optional) The list of IAM policy ARNs that are applied as channel guardrails. The AWS managed 'AdministratorAccess' policy is applied as a default if this is not set.
    logging_level - (Optional) Specifies the logging level for this configuration:ERROR,INFO or NONE. This property affects the log entries pushed to Amazon CloudWatch logs
    user_role_required - (Optional) Enables use of a user role requirement in your chat configuration
    EOT
}

variable "default_sns_topic_arns" {
  type        = list(string)
  description = "Default SNS topic ARNs to apply to all channels"
  default     = []
}

variable "default_iam_role_arn" {
  type        = string
  description = "Default IAM role to apply to all channels"
  default     = ""
}

variable "default_guardrail_policies" {
  type        = list(string)
  description = "Default guardrail policies to apply to all channels"
  default     = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

variable "default_logging_level" {
  type        = string
  description = "Default logging level to apply to all channels"
  default     = "NONE"
}

variable "default_user_role_required" {
  type        = bool
  description = "Default user role required to apply to all channels"
  default     = false
}
