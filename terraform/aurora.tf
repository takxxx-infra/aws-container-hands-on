# ##################################################
# Locals
# ##################################################

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
