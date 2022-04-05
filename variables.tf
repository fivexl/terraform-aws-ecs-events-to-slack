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

variable "custom_event_rules" {
  description = "TBD"
  type = map(object({
    detail-type = any
    detail      = any
  }))
  default = {}
}

############

variable "ecs_task_state_event_rule_detail" {
  description = "The content of the `detail` section in the EvenBridge Rule for `ECS Task State Change` events. Use it to filter the events which will be processed and sent to Slack. If set to an empty map, the event rule will not be created."
  type        = any
  default = {
    lastStatus = ["STOPPED"]
  }
}

variable "ecs_deployment_state_event_rule_detail" {
  description = "The content of the `detail` section in the EvenBridge Rule for `ECS Deployment State Change` events. Use it to filter the events which will be processed and sent to Slack. If set to an empty map, the event rule will not be created."
  type        = any
  default = {
    eventType = ["ERROR"]
  }
}

variable "ecs_service_action_event_rule_detail" {
  description = "The content of the `detail` section in the EvenBridge Rule for `ECS Service Action` events. Use it to filter the events which will be processed and sent to Slack. If set to an empty map, the event rule will not be created."
  type        = any
  default = {
    eventType = ["WARN", "ERROR"]
  }
}
