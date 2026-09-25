############################################################
# Ressources EXISTANTES (lecture seule)
############################################################
data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_internet_gateway" "main" {
  internet_gateway_id = var.igw_id
}

data "aws_nat_gateway" "main" {
  id = var.nat_gateway_id
}

# Dernière AMI Amazon Linux 2023 (SSM Agent pré-intégré)
data "aws_ssm_parameter" "al2023" {
  name = var.ami_ssm_parameter
}

# Détection de l'IP publique de l'admin pour la règle SSH
data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com"
}
