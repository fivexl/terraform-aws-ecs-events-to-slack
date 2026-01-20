terraform {
  backend "s3" {
    bucket         = "fivexl-tf-state-bucket"
    key            = "simon-tingle/terraform-aws-ecs-events-to-slack.tfstate"
    region         = "us-east-1"
    dynamodb_table = "fivexl-task-tf-lock-table"
    encrypt        = true
  }
}