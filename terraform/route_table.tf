# ##################################################
# Locals
# ##################################################
locals {
  management_subnets = [
    aws_subnet.this["public-management-a"],
    aws_subnet.this["public-management-c"]
  ]
}

# ##################################################
# Ingress
# ##################################################
resource "aws_route_table" "ingress" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.project_name}-ingress"
  }
}

resource "aws_route_table_association" "ingress" {
  for_each = {
    public-ingress-a = aws_subnet.this["public-ingress-a"]
    public-ingress-c = aws_subnet.this["public-ingress-c"]
  }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.ingress.id
}

# ##################################################
# App
# ##################################################
resource "aws_route_table" "app" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-app"
  }
}

resource "aws_route_table_association" "app" {
  for_each = {
    private-app-a = aws_subnet.this["private-app-a"]
    private-app-c = aws_subnet.this["private-app-c"]
  }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app.id
}

# ##################################################
# Management
# ##################################################
resource "aws_route_table" "management" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.project_name}-management"
  }
}

resource "aws_route_table_association" "management" {
  for_each = {
    public-management-a = aws_subnet.this["public-management-a"]
    public-management-c = aws_subnet.this["public-management-c"]
  }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.management.id
}
