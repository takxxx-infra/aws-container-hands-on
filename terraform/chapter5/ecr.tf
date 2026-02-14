# ##################################################
# Locals
# ##################################################
locals {
  ecr = toset([
    "frontend-app",
    "backend-app"
  ])
}

# ##################################################
# ECR
# ##################################################
resource "aws_ecr_repository" "this" {
  for_each             = local.ecr
  name                 = "${local.project_name}-${each.key}"
  image_tag_mutability = "MUTABLE"
}
