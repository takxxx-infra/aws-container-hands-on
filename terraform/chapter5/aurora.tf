# ##################################################
# Subnet Group
# ##################################################
resource "aws_db_subnet_group" "main" {
  name        = "${local.project_name}-main"
  description = "DB subnet group for Aurora"
  subnet_ids = [
    aws_subnet.this["private-db-a"].id,
    aws_subnet.this["private-db-c"].id
  ]
  tags = {
    Name = "${local.project_name}-main"
  }
}

# ##################################################
# Aurora Cluster
# ##################################################
resource "aws_rds_cluster" "main" {
  cluster_identifier          = "${local.project_name}-main"
  engine                      = "aurora-postgresql"
  engine_version              = "17.4"
  engine_mode                 = "provisioned"
  engine_lifecycle_support    = "open-source-rds-extended-support-disabled"
  database_name               = "app"
  master_username             = "sbcntradmin"
  manage_master_user_password = true
  port                        = 5432

  db_subnet_group_name            = aws_db_subnet_group.main.name
  db_cluster_parameter_group_name = "default.aurora-postgresql17"
  vpc_security_group_ids          = [aws_security_group.db.id]
  network_type                    = "IPV4"
  cluster_members                 = ["sbcntr-main-instance-1"]

  storage_encrypted = true

  backup_retention_period      = 1
  preferred_maintenance_window = "sat:12:00-sat:12:30"
  copy_tags_to_snapshot        = true
  deletion_protection          = true
  skip_final_snapshot          = true

  enable_http_endpoint                = true
  iam_database_authentication_enabled = false

  database_insights_mode                = "standard"
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  serverlessv2_scaling_configuration {
    max_capacity             = 4
    min_capacity             = 0
    seconds_until_auto_pause = 300
  }
}

# ##################################################
# Aurora Instance
# ##################################################
resource "aws_rds_cluster_instance" "main" {
  identifier          = "${local.project_name}-main-instance-1"
  cluster_identifier  = aws_rds_cluster.main.cluster_identifier
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
  instance_class      = "db.serverless"
  availability_zone   = "ap-northeast-1a"
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  promotion_tier      = 1
}
