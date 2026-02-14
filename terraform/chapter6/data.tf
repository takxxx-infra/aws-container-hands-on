data "terraform_remote_state" "chapter5" {
  backend = "s3"

  config = {
    bucket = "sbcntr-s3-terraform-takxxx"
    key    = "tfstate"
    region = "ap-northeast-1"
  }
}
