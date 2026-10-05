############################################################
# Général
############################################################
variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "name_prefix" {
  type    = string
  default = "tech_mind_iac_safta_ahmed"
}

variable "name_suffix" {
  description = "Suffixe ajouté à toutes les ressources pour les distinguer de la partie 01"
  type        = string
  default     = "_modules_ref"
}

variable "default_tags" {
  type    = map(string)
  default = {}
}

############################################################
# Réseau existant (lecture seule)
############################################################
variable "vpc_id" {
  type = string
}

variable "igw_id" {
  type = string
}

variable "nat_gateway_id" {
  type = string
}

variable "availability_zone" {
  type = string
}

# ATTENTION : doivent être DIFFÉRENTS des CIDR de la partie 01 (même VPC)
variable "public_subnet_cidr" {
  type = string
}

variable "private_subnet_cidr" {
  type = string
}

############################################################
# Accès
############################################################
variable "allowed_ssh_cidr" {
  description = "Laisser vide pour détecter automatiquement votre IP publique"
  type        = string
  default     = ""
}

variable "ssh_public_key_path" {
  type = string
}

############################################################
# EC2
############################################################
# variable "ami_ssm_parameter" {
#   type    = string
#   default = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  
# }

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "root_volume_size" {
  type    = number
  default = 8
}

############################################################
# S3
############################################################
variable "s3_bucket_ids" {
  type    = list(string)
  default = ["01", "02"]
}



############################################################
# IAM EXISTANT (aucune création de rôle dans cette partie)
############################################################
variable "instance_profile_name" {
  description = "Instance profile existant avec AmazonSSMManagedInstanceCore"
  type        = string
  default     = "AmazonEC2RoleForSSM"
}

