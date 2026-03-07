# ##################################################
# Locals
# ##################################################
locals {
  port = {
    http = {
      alb          = 80
      alb_test     = 10080
      frontend_app = 8080
      backend_app  = 8081
    }
    https    = 443
    postgres = 5432
  }
}

# ##################################################
# Ingress
# ##################################################
resource "aws_security_group" "ingress" {
  name   = "ingress"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-ingress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ipv4" {
  security_group_id = aws_security_group.ingress.id
  ip_protocol       = "tcp"
  from_port         = local.port.http.alb
  to_port           = local.port.http.alb
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ipv6" {
  security_group_id = aws_security_group.ingress.id
  ip_protocol       = "tcp"
  from_port         = local.port.http.alb
  to_port           = local.port.http.alb
  cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_test_ipv4" {
  security_group_id = aws_security_group.ingress.id
  ip_protocol       = "tcp"
  from_port         = local.port.http.alb_test
  to_port           = local.port.http.alb_test
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_test_ipv6" {
  security_group_id = aws_security_group.ingress.id
  ip_protocol       = "tcp"
  from_port         = local.port.http.alb_test
  to_port           = local.port.http.alb_test
  cidr_ipv6         = "::/0"
}

resource "aws_vpc_security_group_egress_rule" "ingress" {
  security_group_id = aws_security_group.ingress.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ##################################################
# Management
# ##################################################
resource "aws_security_group" "management" {
  name   = "management"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-management"
  }
}

resource "aws_vpc_security_group_egress_rule" "management" {
  security_group_id = aws_security_group.management.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ##################################################
# Frontend App
# ##################################################
resource "aws_security_group" "frontend_app" {
  name   = "frontend-app"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-frontend-app"
  }
}

resource "aws_vpc_security_group_ingress_rule" "frontend_app" {
  security_group_id            = aws_security_group.frontend_app.id
  ip_protocol                  = "tcp"
  from_port                    = local.port.http.frontend_app
  to_port                      = local.port.http.frontend_app
  referenced_security_group_id = aws_security_group.ingress.id
}

resource "aws_vpc_security_group_egress_rule" "frontend" {
  security_group_id = aws_security_group.frontend_app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ##################################################
# Backend App
# ##################################################
resource "aws_security_group" "backend_app" {
  name   = "backend-app"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-backend-app"
  }
}

resource "aws_vpc_security_group_ingress_rule" "backend_app" {
  security_group_id            = aws_security_group.backend_app.id
  ip_protocol                  = "tcp"
  from_port                    = local.port.http.backend_app
  to_port                      = local.port.http.backend_app
  referenced_security_group_id = aws_security_group.frontend_app.id
}

resource "aws_vpc_security_group_egress_rule" "backend" {
  security_group_id = aws_security_group.backend_app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}


# ##################################################
# DB
# ##################################################
resource "aws_security_group" "db" {
  name   = "database"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-db"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db" {
  for_each = {
    backend_app = aws_security_group.backend_app.id
    management  = aws_security_group.management.id
  }

  security_group_id            = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = local.port.postgres
  to_port                      = local.port.postgres
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_egress_rule" "db" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ##################################################
# VPC Endpoint
# ##################################################
resource "aws_security_group" "vpce" {
  name   = "egress"
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-vpce"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpce" {
  for_each = {
    backend_app  = aws_security_group.backend_app.id
    frontend_app = aws_security_group.frontend_app.id
    management   = aws_security_group.management.id
  }
  security_group_id            = aws_security_group.vpce.id
  ip_protocol                  = "tcp"
  from_port                    = local.port.https
  to_port                      = local.port.https
  referenced_security_group_id = each.value
}

resource "aws_vpc_security_group_egress_rule" "vpce" {
  security_group_id = aws_security_group.vpce.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
