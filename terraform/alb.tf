# ##################################################
# Locals
# ##################################################
locals {
  target_group = {
    frontapp-blue = {
      target_type      = "ip"
      protocol         = "HTTP"
      port             = 8080
      ip_address_type  = "ipv4"
      protocol_version = "HTTP1"
    }
    frontapp-green = {
      target_type      = "ip"
      protocol         = "HTTP"
      port             = 8080
      ip_address_type  = "ipv4"
      protocol_version = "HTTP1"
    }
  }
}

# ##################################################
# Target Group
# ##################################################
resource "aws_lb_target_group" "this" {
  for_each         = local.target_group
  name             = "${local.project_name}-${each.key}"
  target_type      = each.value.target_type
  protocol         = each.value.protocol
  port             = each.value.port
  ip_address_type  = each.value.ip_address_type
  vpc_id           = aws_vpc.main.id
  protocol_version = each.value.protocol_version
  health_check {
    protocol            = "HTTP"
    path                = "/healthcheck"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200"
    enabled             = true
  }
}

# ##################################################
# ALB
# ##################################################
resource "aws_lb" "ingress" {
  load_balancer_type = "application"
  name               = "${local.project_name}-ingress"
  internal           = false
  ip_address_type    = "ipv4"
  subnets = [
    aws_subnet.this["public-ingress-a"].id,
    aws_subnet.this["public-ingress-c"].id
  ]
  security_groups = [
    aws_security_group.ingress.id
  ]
}

# ##################################################
# ALB Listener
# ##################################################
resource "aws_lb_listener" "ingress" {
  protocol          = "HTTP"
  port              = 80
  load_balancer_arn = aws_lb.ingress.arn
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.this["frontapp-blue"].arn
        weight = 1
      }
      target_group {
        arn    = aws_lb_target_group.this["frontapp-green"].arn
        weight = 0
      }
    }
  }
}
