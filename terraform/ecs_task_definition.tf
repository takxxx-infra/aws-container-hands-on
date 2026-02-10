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
        awslogs-group         = "/ecs/sbcntr-frontend-app"
        awslogs-region        = "ap-northeast-1"
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
  region                   = "ap-northeast-1"
  requires_compatibilities = ["FARGATE"]
  skip_destroy             = null
  task_role_arn            = null
  track_latest             = false
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}
