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
  container_definitions = jsonencode([{
    name              = "app"
    image             = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/sbcntr-frontend-app:${local.image_tag.frontend_app}"
    cpu               = 0
    memoryReservation = 512
    portMappings = [{
      appProtocol   = "http"
      containerPort = 8080
      hostPort      = 8080
      name          = "app-8080-tcp"
      protocol      = "tcp"
    }]
    essential = true
    environment = [{
      name  = "BACKEND_FQDN"
      value = "backend-app.sbcntr.local"
      }, {
      name  = "BACKEND_PORT"
      value = "8081"
    }]
    environmentFiles       = []
    mountPoints            = []
    volumesFrom            = []
    readonlyRootFilesystem = true
    ulimits                = []
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-create-group  = "true"
        awslogs-group         = "/sbcntr/ecs/frontend-app"
        awslogs-region        = "${local.region}"
        awslogs-stream-prefix = "ecs"
      }
      secretOptions = []
    }
    memoryReservation = 512
    systemControls    = []
  }])
  cpu                      = "512"
  enable_fault_injection   = false
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  family                   = "sbcntr-frontend-app"
  ipc_mode                 = null
  memory                   = "1024"
  network_mode             = "awsvpc"
  pid_mode                 = null
  requires_compatibilities = ["FARGATE"]
  skip_destroy             = null
  task_role_arn            = null
  track_latest             = false
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_task_definition" "backend_app" {
  container_definitions = jsonencode([{
    name              = "app"
    image             = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/sbcntr-backend-app:${local.image_tag.backend_app}"
    cpu               = 256
    memoryReservation = 256
    links             = []
    portMappings = [{
      containerPort = 8081
      hostPort      = 8081
      protocol      = "tcp"
    }]
    essential  = true
    entryPoint = []
    command    = []
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
    environmentFiles      = []
    mountPoints           = []
    volumesFrom           = []
    dnsServers            = []
    dnsSearchDomains      = []
    extraHosts            = []
    dockerSecurityOptions = []
    dockerLabels          = {}
    ulimits               = []
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/sbcntr/ecs/backend-app"
        awslogs-region        = "${local.region}"
        awslogs-stream-prefix = "ecs"
      }
      secretOptions = []
    }
    systemControls  = []
    credentialSpecs = []
  }])
  cpu                      = "256"
  enable_fault_injection   = false
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  family                   = "sbcntr-backend-app"
  ipc_mode                 = null
  memory                   = "512"
  network_mode             = "awsvpc"
  pid_mode                 = null
  requires_compatibilities = ["FARGATE"]
  skip_destroy             = null
  task_role_arn            = null
  track_latest             = false
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}
