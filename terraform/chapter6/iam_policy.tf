# ##################################################
# CodeBuildBasePolicy
# ##################################################
resource "aws_iam_policy" "code_build_base" {
  name = "CodeBuildBasePolicy-SbcntrCodebuildRole"
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
          "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${aws_codebuild_project.frontend_app.name}",
          "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${aws_codebuild_project.frontend_app.name}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::codepipeline-${local.region}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:CreateReportGroup",
          "codebuild:CreateReport",
          "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases",
          "codebuild:BatchPutCodeCoverages"
        ]
        Resource = [
          "${aws_codebuild_project.frontend_app.arn}"
        ]
      }
    ]
  })
}

# ##################################################
# CodeBuildCodeConnectionsSourceCredentialsPolicy
# ##################################################
resource "aws_iam_policy" "code_build_code_connection" {
  name = "CodeBuildCodeConnectionsSourceCredentialsPolicy-SbcntrCodebuildRole"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:GetConnectionToken",
          "codestar-connections:GetConnection",
          "codeconnections:GetConnectionToken",
          "codeconnections:GetConnection",
          "codeconnections:UseConnection"
        ]
        Resource = [
          "${aws_codeconnections_connection.github.arn}"
        ]
      }
    ]
  })
}

# ##################################################
# AWSCodePipelineServiceRole
# ##################################################
resource "aws_iam_policy" "code_pipeline_serivice_role" {
  name = "AWSCodePipelineServiceRolePolicy-SbcntrPipelineRole"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::codepipeline-${local.region}-*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "arn:aws:s3:::codepipeline-${local.region}-*/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = "${data.aws_caller_identity.current.account_id}"
          }
        }
      }
    ]
  })
}

# ##################################################
# CodePipeline-CodeBuild
# ##################################################
resource "aws_iam_policy" "code_pipeline_code_build" {
  name = "CodePipeline-CodeBuildPolicy-SbcntrPipelineRole"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuildBatches",
          "codebuild:StartBuildBatch"
        ]
        Resource = [
          "${aws_codebuild_project.frontend_app.arn}"
        ]
      }
    ]
  })
}

# ##################################################
# CodePipeline-CodeConnections
# ##################################################
resource "aws_iam_policy" "code_pipeline_code_connections" {
  name = "CodePipeline-CodeConnectionsPolicy-SbcntrPipelineRole"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codeconnections:UseConnection",
          "codestar-connections:UseConnection"
        ]
        Resource = [
          "${aws_codeconnections_connection.github.arn}"
        ]
      }
    ]
  })
}

# ##################################################
# CodePipeline-ECSDeploy
# ##################################################
resource "aws_iam_policy" "code_pipeline_ecs_deploy" {
  name = "CodePipeline-ECSDeployPolicy-SbcntrPipelineRole"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeTaskDefinition",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]
        Resource = [
          "${data.terraform_remote_state.chapter5.outputs.ecs_service_arn_frontend_app}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:TagResource"
        ]
        Resource = [
          "${data.terraform_remote_state.chapter5.outputs.ecs_task_definition_arn_frontend_app}"
        ]
        Condition = {
          StringEquals = {
            "ecs:CreateAction" = [
              "RegisterTaskDefinition"
            ]
          }
        }
      }
    ]
  })
}
