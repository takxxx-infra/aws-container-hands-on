# ##################################################
# Locals
# ##################################################
locals {
}


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

# ##################################################
# ECS Service
# ##################################################
resource "aws_ecs_service" "frontend_app" {
  name                               = "${local.project_name}-frontend-app"
  task_definition                    = aws_ecs_task_definition.frontend_app.arn
  availability_zone_rebalancing      = "ENABLED"
  cluster                            = aws_ecs_cluster.main.arn
  platform_version                   = "LATEST"
  scheduling_strategy                = "REPLICA"
  desired_count                      = 1
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  enable_ecs_managed_tags            = true
  enable_execute_command             = false
  health_check_grace_period_seconds  = 60
  propagate_tags                     = "NONE"


  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    base              = 0
    weight            = 1
  }
  deployment_controller {
    type = "ECS"
  }
  deployment_configuration {
    strategy             = "BLUE_GREEN"
    bake_time_in_minutes = "1"
  }
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  load_balancer {
    container_name   = "app"
    container_port   = 8080
    target_group_arn = aws_lb_target_group.this["frontapp-blue"].arn
    advanced_configuration {
      alternate_target_group_arn = aws_lb_target_group.this["frontapp-green"].arn
      production_listener_rule   = aws_lb_listener_rule.ingress_production.arn
      role_arn                   = aws_iam_role.ecs_deployment.arn
    }
  }
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.frontend_app.id]
    subnets = [
      aws_subnet.this["private-app-a"].id,
      aws_subnet.this["private-app-c"].id
    ]
  }
}

resource "aws_ecs_service" "backend_app" {
  name                               = "${local.project_name}-backend-app"
  task_definition                    = aws_ecs_task_definition.backend_app.arn
  availability_zone_rebalancing      = "ENABLED"
  cluster                            = aws_ecs_cluster.main.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  desired_count                      = 1
  enable_ecs_managed_tags            = true
  enable_execute_command             = false
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"

  platform_version    = "1.4.0"
  propagate_tags      = "NONE"
  region              = "ap-northeast-1"
  scheduling_strategy = "REPLICA"
  tags = {
    Project = "sbcntr"
  }
  tags_all = {
    Project = "sbcntr"
  }
  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }
  deployment_configuration {
    bake_time_in_minutes = "0"
    strategy             = "ROLLING"
  }
  deployment_controller {
    type = "ECS"
  }
  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.backend_app.id]
    subnets = [
      aws_subnet.this["private-app-a"].id,
      aws_subnet.this["private-app-c"].id
    ]
  }
  service_registries {
    registry_arn = aws_service_discovery_service.sbcntr.arn
  }
}


# ##################################################
# ECS Service Discovery
# ##################################################
resource "aws_service_discovery_private_dns_namespace" "sbcntr" {
  name        = "${local.project_name}.local"
  description = "${local.project_name} local namespace for ECS services"
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "sbcntr" {
  name        = "backend-app"
  description = "Backend App Service"
  dns_config {
    namespace_id   = aws_service_discovery_private_dns_namespace.sbcntr.id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
  health_check_custom_config {
  }

  lifecycle {
    ignore_changes = [health_check_custom_config]
  }
}
