module "chatbot_notifications_only_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.28.0"

  create_policy = var.create_notifications_only_policy
  description   = "NotificationsOnly policy for AWS-Chatbot"
  path          = "/service-role/"
  name_prefix   = "AWS-Chatbot-NotificationsOnly-Policy-"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "cloudwatch:Describe*",
            "cloudwatch:Get*",
            "cloudwatch:List*"
          ],
          "Effect" : "Allow",
          "Resource" : "*"
        }
      ]
    }
  )
  tags = var.tags
}

module "chatbot_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.28.0"

  create_role = var.create_role

  role_path        = "/service-role/"
  role_name_prefix = "AWSChatbot"
  role_description = "IAM role for AWS Chatbot"
  custom_role_policy_arns = [
    module.chatbot_notifications_only_policy.arn
  ]
  custom_role_trust_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "chatbot.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )

  tags = var.tags
}

