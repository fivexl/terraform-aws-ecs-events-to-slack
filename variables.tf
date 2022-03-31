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
