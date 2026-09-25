############################################
# Général
############################################
variable "aws_region" {
  description = "Région AWS (Paris)"
  type        = string
  default     = "eu-west-3"
}

variable "name_prefix" {
  description = "Préfixe de nommage : tech_mind_iac_<nom>_<prenom>"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9_]+$", var.name_prefix))
    error_message = "name_prefix : minuscules, chiffres et underscores uniquement."
  }
}

variable "default_tags" {
  description = "Tags appliqués automatiquement à toutes les ressources (Owner est utilisé par la policy IAM du déployeur)"
  type        = map(string)
}

############################################
# Réseau existant (pré-requis du TP)
############################################
variable "vpc_id" {
  description = "ID du VPC existant tech_mind_vpc"
  type        = string
}

variable "igw_id" {
  description = "ID de l'Internet Gateway existante tech_mind_igw"
  type        = string
}

variable "nat_gateway_id" {
  description = "ID de la NAT Gateway existante tech_mind_general_use"
  type        = string
}

variable "availability_zone" {
  description = "AZ des subnets"
  type        = string
  default     = "eu-west-3a"
}

variable "public_subnet_cidr" {
  description = "CIDR du subnet public (doit être libre dans 10.0.0.0/16 : VPC partagé !)"
  type        = string

  validation {
    condition     = can(cidrhost(var.public_subnet_cidr, 0))
    error_message = "CIDR invalide."
  }
}

variable "private_subnet_cidr" {
  description = "CIDR du subnet privé (doit être libre dans 10.0.0.0/16 : VPC partagé !)"
  type        = string

  validation {
    condition     = can(cidrhost(var.private_subnet_cidr, 0))
    error_message = "CIDR invalide."
  }
}

############################################
# Accès SSH
############################################
variable "allowed_ssh_cidr" {
  description = "IP autorisée en SSH sur le serveur public (x.x.x.x/32). Vide = IP publique détectée automatiquement."
  type        = string
  default     = ""

  validation {
    condition     = var.allowed_ssh_cidr == "" || (can(cidrhost(var.allowed_ssh_cidr, 0)) && var.allowed_ssh_cidr != "0.0.0.0/0")
    error_message = "allowed_ssh_cidr doit être un CIDR valide et différent de 0.0.0.0/0."
  }
}

variable "ssh_public_key_path" {
  description = "Chemin de la clé publique SSH (générée avec ssh-keygen)"
  type        = string
}

############################################
# EC2
############################################
variable "instance_type" {
  description = "Type d'instance"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Taille du disque racine (Go)"
  type        = number
  default     = 8

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "Amazon Linux 2023 nécessite au moins 8 Go."
  }
}

variable "ami_ssm_parameter" {
  description = "Paramètre SSM public donnant la dernière AMI Amazon Linux 2023"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}


variable "instance_profile_name" {
  description = "Instance profile SSM existant fourni par le compte"
  type        = string
  default     = "AmazonEC2RoleForSSM"
}

############################################
# Arrêt / démarrage automatiques
############################################
variable "stop_schedule_expression" {
  description = "Expression cron EventBridge Scheduler pour l'arrêt"
  type        = string
  default     = "cron(0 19 * * ? *)"
}

variable "start_schedule_expression" {
  description = "Expression cron EventBridge Scheduler pour le démarrage"
  type        = string
  default     = "cron(0 9 * * ? *)"
}

variable "schedule_timezone" {
  description = "Fuseau horaire des planifications (gère l'heure d'été/hiver)"
  type        = string
  default     = "Europe/Paris"
}

variable "log_retention_days" {
  description = "Rétention des logs CloudWatch de la Lambda"
  type        = number
  default     = 14
}

############################################
# S3
############################################
variable "s3_bucket_ids" {
  description = "Identifiants des buckets à créer (2 demandés par le TP)"
  type        = list(string)
  default     = ["01", "02"]
}

variable "ec2_ssm_policy_arn" {
  description = "Policy managée attachée au rôle EC2 (consigne : AmazonEC2RoleForSSM)"
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleForSSM"
}