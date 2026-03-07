locals {
  region       = "ap-northeast-1"
  project_name = "sbcntr"

  az = {
    a = "ap-northeast-1a"
    c = "ap-northeast-1c"
  }
}

locals {
  approval_action_group             = "ecs-bg-approval"
  approval_action_value             = "approved"
  rollback_action_value             = "rollback"
  approval_lambda_name              = "${local.project_name}-ecs-bg-approval"
  approval_lambda_zip_path          = "${path.module}/.terraform/${local.approval_lambda_name}.zip"
  approval_parameter_prefix_trimmed = trimsuffix(var.approval_parameter_prefix, "/")
  approval_parameter_arn_pattern    = "arn:${data.aws_partition.current.partition}:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/${trimprefix(local.approval_parameter_prefix_trimmed, "/")}/*"
  approve_action_name               = "${local.project_name}-ecs-bg-reroute"
  rollback_action_name              = "${local.project_name}-ecs-bg-rollback"
  chatbot_execution_role_name       = element(reverse(split("/", var.chatbot_execution_role_arn)), 0)
  chatbot_region                    = var.chatbot_region
}
