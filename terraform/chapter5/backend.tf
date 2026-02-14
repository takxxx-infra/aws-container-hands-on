terraform {
  backend "s3" {
    bucket       = "sbcntr-s3-terraform-takxxx"
    key          = "tfstate"
    region       = "ap-northeast-1"
    use_lockfile = true
  }
}
