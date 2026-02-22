# ##################################################
# CodePipeline Frontend app
# ##################################################
resource "aws_codepipeline" "frontend_app" {
  name           = "${local.project_name}-frontend-app"
  role_arn       = aws_iam_role.code_pipeline.arn
  pipeline_type  = "V2"
  execution_mode = "QUEUED"

  artifact_store {
    location = "codepipeline-ap-northeast-1-24b0b88ef19c-4ff7-bdb7-fb5607a6d090"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      run_order        = 1
      namespace        = "SourceVariables"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        BranchName           = "v2"
        ConnectionArn        = "arn:aws:codeconnections:ap-northeast-1:455322614919:connection/f2226e0d-5cbc-4517-9f14-5140ae3c5e50"
        DetectChanges        = "false"
        FullRepositoryId     = "takxxx-infra/sbcntr-frontend"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }

    on_failure {
      result = "RETRY"

      retry_configuration {
        retry_mode = "ALL_ACTIONS"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      namespace        = "BuildVariables"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      configuration = {
        ProjectName = "sbcntr-frontend-app"
      }
    }

    on_failure {
      result = "RETRY"

      retry_configuration {
        retry_mode = "ALL_ACTIONS"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      run_order       = 1
      namespace       = "DeployVariables"
      input_artifacts = ["BuildArtifact"]
      configuration = {
        ClusterName       = "sbcntr-app"
        DeploymentTimeout = "30"
        ServiceName       = "sbcntr-frontend-app"
      }
    }

    on_failure {
      result = "ROLLBACK"
    }
  }
}
