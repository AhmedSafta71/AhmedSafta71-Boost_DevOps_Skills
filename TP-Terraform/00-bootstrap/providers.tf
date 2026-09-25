# Étape 0 : bootstrap (state LOCAL, exécuté une seule fois)
# Crée la table DynamoDB de verrouillage et les "dossiers" dans le bucket de state.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60, < 7.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}
