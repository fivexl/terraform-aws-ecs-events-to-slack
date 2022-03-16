variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "slack_hook_url" {
  description = "Slack incoming webhook URL"
  type        = string
}

variable "skip_task_stop_codes" {
  description = "ECS Task events stop codes for skip"
  type        = list(string)
  default     = []
}

variable "skip_task_stopped_reasons" {
  description = "ECS Task events stopped reasons for skip"
  type        = list(string)
  default     = []
}

