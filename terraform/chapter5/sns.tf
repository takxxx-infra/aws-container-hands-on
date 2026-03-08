# ##################################################
# Topic
# ##################################################
resource "aws_sns_topic" "ecs_bg_deployment" {
  name = "ecs-bg-deployment-sns"
}
