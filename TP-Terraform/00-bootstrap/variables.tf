variable "aws_region" {
  description = "Région AWS (Paris)"
  type        = string
  default     = "eu-west-3"
}

variable "state_bucket" {
  description = "Bucket S3 existant qui héberge les states Terraform"
  type        = string
  default     = "techmind-terraform-state"
}

variable "state_folders" {
  description = "Dossiers à créer dans le bucket de state (Partie 01 et Partie 02)"
  type        = list(string)
  default     = ["safta/", "safta_modules/"]
}

variable "lock_table_name" {
  description = "Nom de la table DynamoDB de verrouillage du state"
  type        = string
  default     = "tech_mind_safta_ahmed_dynamodb_tflock"
}

variable "default_tags" {
  description = "Tags appliqués à toutes les ressources"
  type        = map(string)
}
