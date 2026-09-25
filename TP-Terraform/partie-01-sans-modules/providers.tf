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

  # Backend distant : state dans s3://techmind-terraform-state/safta/terraform.tfstate
  # Verrouillage via DynamoDB (créée par ../00-bootstrap).
  # NB : les blocs backend n'acceptent pas de variables -> valeurs en dur.
  backend "s3" {
    bucket  = "techmind-terraform-state"
    key     = "safta/terraform.tfstate"
    region  = "eu-west-3"
    encrypt = true
    # dynamodb_table = "tech_mind_safta_ahmed_dynamodb_tflock"
  }
}

# Authentification : AUCUNE clé dans le code.
# Le provider lit AWS_PROFILE (SSO ou profil access key) - voir README.
provider "aws" {
  region = var.aws_region

  # default_tags {
  #   tags = var.default_tags
  # }
}
