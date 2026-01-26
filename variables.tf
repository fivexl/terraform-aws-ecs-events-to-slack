# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "name" {
  description = "The string which will be used for the name of AWS Lambda function and other created resources"
  type        = string
}

variable "image_version" {
  description = "The ECR image tag to deploy (e.g., v1.0.0)"
  type        = string
  default     = "v0.1.1"
}

variable "slack_webhook_url" {
  description = <<EOT
  (default) A Slack incoming webhook URL. 
  (if slack_webhook_url_source_type is 'secret') A secretsmanager secret name 
  (if slack_webhook_url_source_type is 'ssm') The full path to the SSM parameter including the initial slash.
  EOT
  type        = string
}


# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# ---------------------------------------------------------------------------------------------------------------------

variable "role_name" {
  description = "The string which will be used for the name of Lambda IAM role"
  type        = string
  default     = null
}

variable "create_role" {
  description = "Controls whether IAM role for Lambda Function should be created"
  type        = bool
  default     = true
}

variable "lambda_role" {
  description = "IAM role ARN attached to the Lambda Function. This governs both who / what can invoke your Lambda Function, as well as what resources our Lambda Function has access to. See Lambda Permission Model for more details."
  type        = string
  default     = ""
}

variable "slack_webhook_url_source_type" {
  description = "Define where to get the slack webhook URL for variable slack_webhook_url. Either as text input or from an AWS secretsmanager lookup"
  validation {
    condition     = contains(["text", "secretsmanager", "ssm"], var.slack_webhook_url_source_type)
    error_message = "Invalid source type. Must be one of 'text', 'secretsmanager', 'ssm'."
  }
  type    = string
  default = "text"
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
    stoppedReason = [{ "anything-but" : { "prefix" : "Scaling activity initiated by (deployment ecs-svc/" } }] 
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

variable "github_repo" {
  description = "The GitHub repository in format 'org/repo'"
  type        = string
  default     = "simon-tingle/terraform-aws-ecs-events-to-slack"
}

variable "recreate_missing_package" {
  description = "Whether to recreate missing Lambda package"
  type        = bool
  default     = true
}

variable "ecr_repo_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "ecs-events-to-slack-repo"
}