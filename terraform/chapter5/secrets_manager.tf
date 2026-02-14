# ##################################################
# RDS sbcntruser
# ##################################################
resource "aws_secretsmanager_secret" "db_app_user" {
  name        = "${local.project_name}-db-app-user"
  description = "RDS DB app user"
}
