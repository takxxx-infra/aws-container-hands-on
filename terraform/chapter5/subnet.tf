# ##################################################
# Locals
# ##################################################
locals {
  subnets = {
    public-ingress-a = {
      cidr     = "10.0.0.0/24"
      az       = local.az.a
      type_tag = "Public"
    }
    public-ingress-c = {
      cidr     = "10.0.1.0/24"
      az       = local.az.c
      type_tag = "Public"
    }
    private-app-a = {
      cidr     = "10.0.8.0/24"
      az       = local.az.a
      type_tag = "Isolated"
    }
    private-app-c = {
      cidr     = "10.0.9.0/24"
      az       = local.az.c
      type_tag = "Isolated"
    }
    private-db-a = {
      cidr     = "10.0.16.0/24"
      az       = local.az.a
      type_tag = "Isolated"
    }
    private-db-c = {
      cidr     = "10.0.17.0/24"
      az       = local.az.c
      type_tag = "Isolated"
    }
    public-management-a = {
      cidr     = "10.0.240.0/24"
      az       = local.az.a
      type_tag = "Public"
    }
    public-management-c = {
      cidr     = "10.0.241.0/24"
      az       = local.az.c
      type_tag = "Public"
    }
    private-egress-a = {
      cidr     = "10.0.248.0/24"
      az       = local.az.a
      type_tag = "Isolated"
    }
    private-egress-c = {
      cidr     = "10.0.249.0/24"
      az       = local.az.c
      type_tag = "Isolated"
    }
  }
}
# ##################################################
# Subnets
# ##################################################
resource "aws_subnet" "this" {
  for_each                = local.subnets
  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = strcontains(each.key, "public")
  tags = {
    Name = "${local.project_name}-${each.key}"
    Type = each.value.type_tag
  }
}

