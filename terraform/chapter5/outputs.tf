output "ecs_service_arn_frontend_app" {
  value = aws_ecs_service.frontend_app.arn
}

output "ecs_task_definition_arn_frontend_app" {
  value = aws_ecs_task_definition.frontend_app.arn_without_revision
}

output "alb_dns_name" {
  value = aws_lb.ingress.dns_name
}

output "frontend_test_listener_url" {
  value = "http://${aws_lb.ingress.dns_name}:${local.port.http.alb_test}/"
}

output "approval_lambda_arn" {
  value = aws_lambda_function.ecs_bg_approval.arn
}

output "approval_lambda_name" {
  value = aws_lambda_function.ecs_bg_approval.function_name
}

output "approval_parameter_prefix" {
  value = local.approval_parameter_prefix_trimmed
}

output "chatbot_custom_action_names" {
  value = {
    approve  = local.approve_action_name
    rollback = local.rollback_action_name
  }
}

output "chatbot_custom_action_arns" {
  value = {
    approve  = awscc_chatbot_custom_action.approve.id
    rollback = awscc_chatbot_custom_action.rollback.id
  }
}
