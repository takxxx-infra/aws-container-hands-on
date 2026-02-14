# ##################################################
# EC2 Management
# ##################################################
resource "aws_iam_role" "ec2_management" {
  name = "PseudoCloud9IamRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_management" {
  for_each = {
    ssm_core           = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ecr_poweruser      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
    ecs_service_update = aws_iam_policy.ecs_service_update.arn
  }
  role       = aws_iam_role.ec2_management.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "ec2_management" {
  name = "PseudoCloud9IamRole"
  role = aws_iam_role.ec2_management.name
}

# ##################################################
# ECS Blue/Green Deployment
# ##################################################
resource "aws_iam_role" "ecs_deployment" {
  name = "EcsInfrastructureRoleForLoadBalancers"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_deployment" {
  for_each = {
    ecs         = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
    ecs_for_alb = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForLoadBalancers"
  }
  role       = aws_iam_role.ecs_deployment.name
  policy_arn = each.value
}

# ##################################################
# ECS Task Execution ROle
# ##################################################
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  for_each = {
    secret = aws_iam_policy.get_secret_sbcntr.arn
  }
  role       = "ecsTaskExecutionRole"
  policy_arn = each.value
}
