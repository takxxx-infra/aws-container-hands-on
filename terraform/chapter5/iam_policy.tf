# ##################################################
# ECSServiceUpdatePolicy
# ##################################################
resource "aws_iam_policy" "ecs_service_update" {
  name = "ECSServiceUpdatePolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:DescribeClusters",
          "ecs:ListServices",
          "ecs:ListClusters",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:ExecuteCommand",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:StartSession"
        ]
        Resource = [
          "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:document/AmazonECS-ExecuteInteractiveCommand",
          "arn:aws:ecs:${local.region}:${data.aws_caller_identity.current.account_id}:task/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })
}

# ##################################################
# SbcntrGettingSecretPolicy
# ##################################################
resource "aws_iam_policy" "get_secret_sbcntr" {
  name = "SbcntrGettingSecretPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "${aws_secretsmanager_secret.db_app_user.arn}"
      }
    ]
  })
}
