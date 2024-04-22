terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0.6"
}

provider "aws" {
  region  = var.main_region
  profile = var.profile_name
}

