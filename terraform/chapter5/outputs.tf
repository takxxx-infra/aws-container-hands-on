output "ecs_service_arn_frontend_app" {
  value = aws_ecs_service.frontend_app.arn
}

output "ecs_task_definition_arn_frontend_app" {
  value = aws_ecs_task_definition.frontend_app.arn_without_revision
}
