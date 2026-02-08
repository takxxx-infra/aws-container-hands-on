# ##################################################
# VPC Endpoint
# ##################################################
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${local.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.vpce.id]
  subnet_ids = [
    aws_subnet.this["private-egress-a"].id,
    aws_subnet.this["private-egress-c"].id
  ]
  private_dns_enabled = true

  tags = {
    Name = "${local.project_name}-ecr-api"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = aws_vpc.main.id
  service_name       = "com.amazonaws.${local.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  security_group_ids = [aws_security_group.vpce.id]
  subnet_ids = [
    aws_subnet.this["private-egress-a"].id,
    aws_subnet.this["private-egress-c"].id
  ]
  private_dns_enabled = true

  tags = {
    Name = "${local.project_name}-ecr-dkr"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${local.region}.s3"
  route_table_ids = [
    aws_route_table.app.id
  ]

  tags = {
    Name = "${local.project_name}-s3"
  }
}
