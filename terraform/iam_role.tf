# ##################################################
# EC2 Management
# ##################################################
resource "aws_iam_role" "ec2_management" {
  name = "PseudoCloud9IamRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_management" {
  for_each = {
    ssm_core           = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    ecr_poweruser      = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
    ecs_service_update = aws_iam_policy.ecs_service_update.arn
  }
  role       = aws_iam_role.ec2_management.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "ec2_management" {
  name = "PseudoCloud9IamRole"
  role = aws_iam_role.ec2_management.name
}
