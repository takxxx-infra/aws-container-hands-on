# ##################################################
# ECS Cluster
# ##################################################
resource "aws_ecs_cluster" "main" {
  name = "${local.project_name}-app"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  capacity_providers = ["FARGATE"]
  cluster_name       = aws_ecs_cluster.main.name
}
