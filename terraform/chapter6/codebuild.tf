# ##################################################
# CodeBuild Frontend app
# ##################################################
resource "aws_codebuild_project" "frontend_app" {
  name               = "${local.project_name}-frontend-app"
  project_visibility = "PRIVATE"
  source_version     = "v2"
  source {
    git_clone_depth     = 1
    insecure_ssl        = false
    location            = local.github.frontend_app
    report_build_status = false
    type                = "GITHUB"
    auth {
      resource = aws_codeconnections_connection.github.arn
      type     = "CODECONNECTIONS"
    }
    git_submodules_config {
      fetch_submodules = false
    }
  }
  artifacts {
    encryption_disabled    = false
    override_artifact_name = false
    type                   = "NO_ARTIFACTS"
  }
  cache {
    modes = ["LOCAL_DOCKER_LAYER_CACHE"]
    type  = "LOCAL"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux-aarch64-standard:3.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    type                        = "ARM_CONTAINER"
    environment_variable {
      name  = "AWS_REGION"
      type  = "PLAINTEXT"
      value = local.region
    }
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      type  = "PLAINTEXT"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name  = "APP_NAME"
      type  = "PLAINTEXT"
      value = "${local.project_name}-frontend-app"
    }
  }

  service_role   = aws_iam_role.code_build.arn
  encryption_key = "arn:aws:kms:${local.region}:${data.aws_caller_identity.current.account_id}:alias/aws/s3"

  badge_enabled = true
  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
    s3_logs {
      encryption_disabled = false
      status              = "DISABLED"
    }
  }

  concurrent_build_limit = 1
  auto_retry_limit       = 0
  build_timeout          = 60
  queued_timeout         = 480
}
