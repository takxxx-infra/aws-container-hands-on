# ##################################################
# Locals
# ##################################################
locals {
  image_tag = {
    frontend_app = "v1.0.1"
    backend_app  = "v1"
  }
}

# ##################################################
# ECS Task Definition
# ##################################################
resource "aws_ecs_task_definition" "frontend_app" {
  family                   = "sbcntr-frontend-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([{
    name      = "app"
    image     = "${aws_ecr_repository.this["frontend-app"].repository_url}:${local.image_tag.frontend_app}"
    essential = true
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }]
    environment = [{
      name  = "BACKEND_FQDN"
      value = "backend-app.${aws_service_discovery_private_dns_namespace.sbcntr.name}"
      }, {
      name  = "BACKEND_PORT"
      value = "8081"
    }]
    cpu                    = 0
    memoryReservation      = 512
    readonlyRootFilesystem = true
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-create-group  = "true"
        awslogs-group         = "${aws_cloudwatch_log_group.this["frontend-app"].name}"
        awslogs-region        = "${local.region}"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "backend_app" {
  family                   = "sbcntr-backend-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([{
    name      = "app"
    image     = "${aws_ecr_repository.this["backend-app"].repository_url}:${local.image_tag.backend_app}"
    essential = true
    portMappings = [{
      containerPort = 8081
      hostPort      = 8081
      protocol      = "tcp"
    }]
    environment = [
      {
        name  = "DB_NAME"
        value = "${aws_rds_cluster.main.database_name}"
      },
      {
        name  = "DB_CONN"
        value = "1"
      }
    ]
    secrets = [
      {
        name      = "DB_HOST"
        valueFrom = "${aws_secretsmanager_secret.db_app_user.arn}:host::"
      },
      {
        name      = "DB_USERNAME"
        valueFrom = "${aws_secretsmanager_secret.db_app_user.arn}:username::"
      },
      {
        name      = "DB_PASSWORD"
        valueFrom = "${aws_secretsmanager_secret.db_app_user.arn}:password::"
      },
    ]
    cpu               = 256
    memoryReservation = 256
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "${aws_cloudwatch_log_group.this["backend-app"].name}"
        awslogs-region        = "${local.region}"
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}
