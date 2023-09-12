# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The string which will be used for the name of AWS Lambda function and other creaated resources"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL. If slack_webhook_url_secretsmanager_lookup is true then this must match your secretsmanager secret name."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "role_name" {
  description = "The string which will be used for the name of Lambda IAM role"
  type        = string
  default     = null
}

variable "slack_webhook_url_secretsmanager_lookup" {
  description = "Lookup the slack incoming webhook URL stored in AWS secrets manager. slack_webhook_url must match your secretsmanager secret name."
  type        = bool
  default     = false
}

variable "enable_ecs_task_state_event_rule" {
  description = "The boolean flag enabling the EvenBridge Rule for `ECS Task State Change` events. The `detail` section of this rule is configured with `ecs_task_state_event_rule_detail` variable."
  type        = bool
  default     = true
}

variable "enable_ecs_deployment_state_event_rule" {
  description = "The boolean flag enabling the EvenBridge Rule for `ECS Deployment State Change` events. The `detail` section of this rule is configured with `ecs_deployment_state_event_rule_detail` variable."
  type        = bool
  default     = true
}

variable "enable_ecs_service_action_event_rule" {
  description = "The boolean flag enabling the EvenBridge Rule for `ECS Service Action` events. The `detail` section of this rule is configured with `ecs_service_action_event_rule_detail` variable."
  type        = bool
  default     = true
}

variable "ecs_task_state_event_rule_detail" {
  description = "The content of the `detail` section in the EvenBridge Rule for `ECS Task State Change` events. Use it to filter the events which will be processed and sent to Slack."
  type        = any
  default = {
    lastStatus    = ["STOPPED"]
    stoppedReason = [{ "anything-but" : { "prefix" : "Scaling activity initiated by (deployment ecs-svc/" } }] # skip task stopped events triggerd by deployments
  }
}

variable "ecs_deployment_state_event_rule_detail" {
  description = "The content of the `detail` section in the EvenBridge Rule for `ECS Deployment State Change` events. Use it to filter the events which will be processed and sent to Slack."
  type        = any
  default = {
    eventType = ["ERROR"]
  }
}

variable "ecs_service_action_event_rule_detail" {
  description = "The content of the `detail` section in the EvenBridge Rule for `ECS Service Action` events. Use it to filter the events which will be processed and sent to Slack."
  type        = any
  default = {
    eventType = ["WARN", "ERROR"]
  }
}

variable "custom_event_rules" {
  description = "A map of objects representing the custom EventBridge rule which will be created in addition to the default rules."
  type        = any
  default     = {}

  validation {
    error_message = "Each rule object should have both 'detail' and 'detail-type' keys."
    condition     = alltrue([for name, rule in var.custom_event_rules : length(setintersection(keys(rule), ["detail", "detail-type"])) == 2])
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "recreate_missing_package" {
  description = "Whether to recreate missing Lambda package if it is missing locally or not."
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653."
  type        = number
  default     = 14
}

variable "lambda_memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime. Valid value between 128 MB to 10,240 MB (10 GB), in 64 MB increments."
  type        = number
  default     = 256
}
