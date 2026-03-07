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

# ##################################################
# ECS Blue/Green Approval Policies
# ##################################################
resource "aws_iam_role_policy" "ecs_bg_approval_lambda" {
  name = "${local.approval_lambda_name}-policy"
  role = aws_iam_role.ecs_bg_approval_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:${data.aws_partition.current.partition}:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.approval_lambda_name}:*",
          "arn:${data.aws_partition.current.partition}:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.approval_lambda_name}:*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${local.region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter",
          "ssm:DeleteParameter"
        ]
        Resource = local.approval_parameter_arn_pattern
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = var.approval_sns_topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:ListServiceDeployments"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_lifecycle_hook" {
  name = "${local.project_name}-ecs-lifecycle-hook"
  role = aws_iam_role.ecs_lifecycle_hook.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = aws_lambda_function.ecs_bg_approval.arn
    }]
  })
}

resource "aws_iam_policy" "chatbot_custom_actions" {
  name = "${local.project_name}-chatbot-custom-actions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter"
        ]
        Resource = local.approval_parameter_arn_pattern
      }
    ]
  })
}
