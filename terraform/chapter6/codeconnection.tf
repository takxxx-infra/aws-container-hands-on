# ##################################################
# CodeConnection
# ##################################################
resource "aws_codeconnections_connection" "github" {
  name          = "SbcntrGitHubConnection"
  provider_type = "GitHub"
}
