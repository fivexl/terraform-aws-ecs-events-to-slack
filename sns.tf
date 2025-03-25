resource "aws_sns_topic" "prod_chatbot" {
  name = "test_chatbot_topic"
}

resource "aws_sns_topic_policy" "prod_chatbot" {
  arn = aws_sns_topic.prod_chatbot.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "chatbot_topic_policy"
    Statement = [
      {
        Sid    = "AllowSNSPublish"
        Effect = "Allow"
        # Principal = "*"
        Principal = {
          "Service" : "chatbot.amazonaws.com"
        },
        Action   = "sns:Publish"
        Resource = aws_sns_topic.prod_chatbot.arn
      },
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          "AWS" : module.amazon_q_notifications.lambda_role_arn
        },
        Action   = "sns:Publish"
        Resource = aws_sns_topic.prod_chatbot.arn
      },
      # {
      #   Sid       = "AllowSNSSubscriptions"
      #   Effect    = "Allow"
      #   Principal = "*"
      #   Action    = "sns:Subscribe"
      #   Resource  = aws_sns_topic.prod_chatbot.arn
      # },
      {
        Sid    = "AllowChatbotSubscriptions"
        Effect = "Allow"
        Principal = {
          "Service" : "chatbot.amazonaws.com"
        },
        Action   = "sns:Subscribe"
        Resource = aws_sns_topic.prod_chatbot.arn
      }
    ]
  })
}
