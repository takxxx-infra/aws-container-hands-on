terraform {
  backend "s3" {
    bucket       = "sbcntr-s3-terraform-682120332115"
    key          = "chapter5/tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
  }
}
