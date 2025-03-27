output "sns_topic_arn" {
  description = "The ARN of the SNS topic used for notifications"
  value       = aws_sns_topic.prod_chatbot.arn
} 
