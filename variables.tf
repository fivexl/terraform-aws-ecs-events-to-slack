variable "name" {
  description = "The string which will be used for the name of AWS Lambda function and other creaated resources"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

############

variable "event_rules" {
  description = "TBD"
  type        = any
  default     = {}
}
