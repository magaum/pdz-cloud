terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

terraform {
  backend "remote" {
    organization = "gigers"

    workspaces {
      name = "cd-pdz"
    }
  }
}

provider "aws" {
  region = var.region
}

