variable "tags" {
  description = "(Optional) A mapping of tags to assign to all resources."
  type        = map(string)
  default     = {}
}

variable "create_notifications_only_policy" {
  description = "(Optional) Whether to create the AWS-Chatbot-NotificationsOnly-Policy policy. Defaults to true."
  type        = bool
  default     = true
}

variable "create_role" {
  description = "(Optional) Whether to create the AWSChatbot role. Defaults to true."
  type        = bool
  default     = true
}
