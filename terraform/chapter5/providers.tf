terraform {
  required_version = "~> 1.14.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.30.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.0"
    }
  }
}

provider "aws" {
  region = local.region

  default_tags {
    tags = {
      ManagedBy = "terraform"
    }
  }
}

provider "awscc" {
  alias  = "chatbot"
  region = local.chatbot_region
}
