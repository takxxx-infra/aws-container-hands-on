# ##################################################
# CodeBuild Role
# ##################################################
resource "aws_iam_role" "code_build" {
  name = "SbcntrCodebuildRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "code_build" {
  for_each = {
    ecr_power_user  = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
    code_build_base = aws_iam_policy.code_build_base.arn
    code_connection = aws_iam_policy.code_build_code_connection.arn
  }
  role       = aws_iam_role.code_build.name
  policy_arn = each.value
}

# ##################################################
# CodePipeline Role
# ##################################################
resource "aws_iam_role" "code_pipeline" {
  name = "SbcntrCodePipelineRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = "${data.aws_caller_identity.current.account_id}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "code_pipeline" {
  for_each = {
    service_role     = aws_iam_policy.code_pipeline_serivice_role.arn
    code_build       = aws_iam_policy.code_pipeline_code_build.arn
    code_connections = aws_iam_policy.code_pipeline_code_connections.arn
    ecs_deploy       = aws_iam_policy.code_pipeline_ecs_deploy.arn
  }
  role       = aws_iam_role.code_pipeline.name
  policy_arn = each.value
}
