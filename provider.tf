terraform {
  required_version = "> 0.15.1"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md
      version               = "~> 3.0"
      configuration_aliases = [aws.ue1]
    }
  }
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "jameso"

    workspaces {
      name = "Example-Workspace"
    }
}
}


provider "aws" {
  region  = "eu-west-2"
  profile = "iamadmin-prod"
}

provider "aws" {
  alias   = "ue1"
  region  = "us-east-1"
  profile = "iamadmin-prod"
}
