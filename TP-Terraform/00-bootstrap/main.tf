############################################
# Table DynamoDB pour le verrouillage du state
############################################
# resource "aws_dynamodb_table" "tf_lock" {
#   name         = var.lock_table_name
#   billing_mode = "PAY_PER_REQUEST" # pas de capacité provisionnée = coût quasi nul
#   hash_key     = "LockID"          # clé imposée par le backend S3 de Terraform

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   server_side_encryption {
#     enabled = true
#   }

#   tags = {
#     Name = var.lock_table_name
#   }
# }

############################################
# "Dossiers" dans le bucket de state partagé
# (S3 n'a pas de vrais dossiers : objet vide dont la clé finit par "/")
############################################
resource "aws_s3_object" "state_folders" {
  for_each = toset(var.state_folders)

  bucket                 = var.state_bucket
  key                    = each.value
  content                = ""
  server_side_encryption = "AES256"
}
