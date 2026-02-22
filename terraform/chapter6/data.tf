# ##################################################
# chapter5 tfstate
# ##################################################
data "terraform_remote_state" "chapter5" {
  backend = "s3"

  config = {
    bucket = "sbcntr-s3-terraform-takxxx"
    key    = "chapter5/tfstate"
    region = "ap-northeast-1"
  }
}

# ##################################################
# Account ID
# ##################################################
data "aws_caller_identity" "current" {}
