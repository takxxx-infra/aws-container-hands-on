# ##################################################
# Locals
# ##################################################
locals {
  target_groups = toset([
    "frontapp-blue",
    "frontapp-green"
  ])
}

# ##################################################
# Target Group
# ##################################################
resource "aws_lb_target_group" "this" {
  for_each         = local.target_groups
  name             = "${local.project_name}-${each.key}"
  target_type      = "ip"
  protocol         = "HTTP"
  port             = 8080
  ip_address_type  = "ipv4"
  vpc_id           = aws_vpc.main.id
  protocol_version = "HTTP1"
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
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# ##################################################
# ALB Listener Rule
# ##################################################
resource "aws_lb_listener_rule" "ingress_production" {
  listener_arn = aws_lb_listener.ingress.arn
  priority     = 10
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
  action {
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
  lifecycle {
    ignore_changes = [action] // ECS Blue/Green Deployment によって動的にweightが変更されるため
  }
}
