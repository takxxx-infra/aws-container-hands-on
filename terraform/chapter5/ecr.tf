# ##################################################
# Locals
# ##################################################
locals {
  ecr = {
    backend-app = {
      image_tag_mutability = "MUTABLE"
    }
    frontend-app = {
      image_tag_mutability = "MUTABLE"
    }
  }
}

# ##################################################
# ECR
# ##################################################
resource "aws_ecr_repository" "this" {
  for_each             = local.ecr
  name                 = "${local.project_name}-${each.key}"
  image_tag_mutability = each.value.image_tag_mutability
}
