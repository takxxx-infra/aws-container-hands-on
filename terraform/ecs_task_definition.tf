# ##################################################
# ECS Task Definition
# ##################################################
resource "aws_ecs_task_definition" "frontend_app" {
  container_definitions = jsonencode([{
    name = "app"
    environment = [{
      name  = "BACKEND_FQDN"
      value = "backend-app.sbcntr.local"
      }, {
      name  = "BACKEND_PORT"
      value = "8081"
    }]
    environmentFiles = []
    essential        = true
    image            = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/sbcntr-frontend-app:v1"
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
    mountPoints       = []
    portMappings = [{
      appProtocol   = "http"
      containerPort = 8080
      hostPort      = 8080
      name          = "app-8080-tcp"
      protocol      = "tcp"
    }]
    readonlyRootFilesystem = true
    systemControls         = []
    ulimits                = []
    volumesFrom            = []
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
    command               = []
    cpu                   = 256
    credentialSpecs       = []
    dnsSearchDomains      = []
    dnsServers            = []
    dockerLabels          = {}
    dockerSecurityOptions = []
    entryPoint            = []
    environment           = []
    environmentFiles      = []
    essential             = true
    extraHosts            = []
    image                 = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/sbcntr-backend-app:v1"
    links                 = []
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/sbcntr/ecs/backend-app"
        awslogs-region        = "${local.region}"
        awslogs-stream-prefix = "ecs"
      }
      secretOptions = []
    }
    memoryReservation = 256
    mountPoints       = []
    name              = "app"
    portMappings = [{
      containerPort = 8081
      hostPort      = 8081
      protocol      = "tcp"
    }]
    secrets        = []
    systemControls = []
    ulimits        = []
    volumesFrom    = []
  }])
  cpu                      = "256"
  enable_fault_injection   = false
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  family                   = "sbcntr-backend-app"
  ipc_mode                 = null
  memory                   = "512"
  network_mode             = "awsvpc"
  pid_mode                 = null
  region                   = "ap-northeast-1"
  requires_compatibilities = ["FARGATE"]
  skip_destroy             = null
  tags                     = {}
  tags_all                 = {}
  task_role_arn            = null
  track_latest             = false
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}
