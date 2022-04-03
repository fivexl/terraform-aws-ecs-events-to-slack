variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL"
  type        = string
}

##########

variable "ecs_task_state_event_rule_detail" {
  description = "The content of the `detail` section in the EvenBridge Rule for `ECS Task State Change` events. Use it to filter the events which will be processed and sent to Slack. If set to empty map, all events will be matched."
  type        = map(any)
  default = {
    lastStatus = ["STOPPED"]
  }
}

variable "ecs_deployment_state_event_rule_detail" {
  description = "The content of the `detail` section in the EvenBridge Rule for `ECS Deployment State Change` events. Use it to filter the events which will be processed and sent to Slack. If set to empty map, all events will be matched."
  type        = map(any)
  default = {
    eventType = ["ERROR"]
  }
}

variable "ecs_service_action_event_rule_detail" {
  description = "The content of the `detail` section in the EvenBridge Rule for `ECS Service Action` events. Use it to filter the events which will be processed and sent to Slack. If set to empty map, all events will be matched."
  type        = map(any)
  default = {
    eventType = ["WARN", "ERROR"]
  }
}

