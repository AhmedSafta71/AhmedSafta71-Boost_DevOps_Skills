############################################################
# Réseau EXISTANT (lecture seule)
############################################################
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
# data "aws_ssm_parameter" "al2023" {
#   name = var.ami_ssm_parameter
# }

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



# Détection de l'IP publique de l'admin pour la règle SSH
data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com"
}

############################################################
# IAM EXISTANT : consommé uniquement, jamais créé ni modifié
############################################################
data "aws_iam_instance_profile" "ssm" {
  name = var.instance_profile_name
}


