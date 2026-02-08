# ##################################################
# Locals
# ##################################################
locals {
  ec2_instances = {
    pseudo-cloud9 = {
      ami                  = "ami-0976ced58148ef3eb"
      instance_type        = "t4g.small"
      subnet_id            = aws_subnet.this["public-management-a"].id
      security_groups      = [aws_security_group.management.id]
      root_volume_size     = 30
      root_volume_type     = "gp3"
      iam_instance_profile = aws_iam_instance_profile.ec2_management.name
    }
  }
}

# ##################################################
# EC2
# ##################################################
resource "aws_instance" "this" {
  for_each = local.ec2_instances
  tags = {
    Name = "${local.project_name}-${each.key}"
  }

  ami             = each.value.ami
  instance_type   = each.value.instance_type
  subnet_id       = each.value.subnet_id
  security_groups = each.value.security_groups
  root_block_device {
    volume_size           = each.value.root_volume_size
    volume_type           = each.value.root_volume_type
    delete_on_termination = true
  }
  iam_instance_profile = each.value.iam_instance_profile
  user_data            = file("${path.module}/userdata/${each.key}.sh")
}
