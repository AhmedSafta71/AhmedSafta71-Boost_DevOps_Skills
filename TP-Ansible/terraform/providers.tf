provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60, < 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }

  backend "s3" {
    bucket  = "techmind-terraform-state"
    key     = "safta_ansible_tfstate/terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true

  }
}



