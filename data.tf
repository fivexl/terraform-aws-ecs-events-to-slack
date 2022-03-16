data "aws_ecs_cluster" "this" {
  cluster_name = var.ecs_cluster_name
}
