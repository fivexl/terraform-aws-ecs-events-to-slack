terraform {
  backend "s3" {
    bucket         = "terraform-state-a6490666acaa9e18f19bdc1559e7c3acde30c9de"
    key            = "simon-tingle/terraform-aws-ecs-events-to-slack.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-state-lock-a6490666acaa9e18f19bdc1559e7c3acde30c9de"
    encrypt        = true
  }
}