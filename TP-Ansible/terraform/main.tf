############################################################
# TP Terraform - Kodemade / Tech Mind
# PARTIE 02 : avec modules (ressources suffixées _modules_ref)
# Propriétaire : safta_ahmed
############################################################

############################################################
# 1. Réseau : 1 subnet public + 1 subnet privé
############################################################
module "network" {
  source = "./modules/network"

  prefix              = local.prefix
  suffix              = local.suffix
  vpc_id              = data.aws_vpc.main.id
  igw_id              = data.aws_internet_gateway.main.id
  nat_gateway_id      = data.aws_nat_gateway.main.id
  availability_zone   = var.availability_zone
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}


############################################################
# 3. Key pair (clé publique uniquement)
############################################################
resource "aws_key_pair" "admin" {
  key_name   = "${local.prefix}_keypair${local.suffix}"
  public_key = file(pathexpand(var.ssh_public_key_path))

  tags = { Name = "${local.prefix}_keypair${local.suffix}" }
}

############################################################
# 4. EC2 : même module utilisé 2 fois
############################################################
module "front1" {
  source = "./modules/ec2_instance"

  name                        = "${local.prefix}_ec2_front1${local.suffix}"
  ebs_name                    = "${local.prefix}_ebs_front1${local.suffix}"
  role_tag                    = "public-app"
  ami_id                      = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.network.public_subnet_id
  security_group_ids          = [aws_security_group.app.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.admin.key_name
  iam_instance_profile        = data.aws_iam_instance_profile.ssm.name
  user_data                   = file("${path.module}/user_data/app.sh")
  http_put_response_hop_limit = 2 # nécessaire pour les conteneurs Docker
  root_volume_size            = var.root_volume_size
  default_tags                = var.default_tags

  depends_on = [module.network] # route vers l'IGW prête avant le boot
}


module "front2" {
  source = "./modules/ec2_instance"

  name                        = "${local.prefix}_ec2_front2${local.suffix}"
  ebs_name                    = "${local.prefix}_ebs_front2${local.suffix}"
  role_tag                    = "public-app"
  ami_id                      = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.network.public_subnet_id
  security_group_ids          = [aws_security_group.app.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.admin.key_name
  iam_instance_profile        = data.aws_iam_instance_profile.ssm.name
  user_data                   = file("${path.module}/user_data/app.sh")
  http_put_response_hop_limit = 2 # nécessaire pour les conteneurs Docker
  root_volume_size            = var.root_volume_size
  default_tags                = var.default_tags

  depends_on = [module.network] # route vers l'IGW prête avant le boot
}


module "db" {
  source = "./modules/ec2_instance"

  name                        = "${local.prefix}_ec2_db${local.suffix}"
  ebs_name                    = "${local.prefix}_ebs_db${local.suffix}"
  role_tag                    = "private-db"
  ami_id                      = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.network.private_subnet_id
  security_group_ids          = [aws_security_group.db.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.admin.key_name
  iam_instance_profile        = data.aws_iam_instance_profile.ssm.name
  user_data                   = file("${path.module}/user_data/db.sh")
  http_put_response_hop_limit = 1
  root_volume_size            = var.root_volume_size
  default_tags                = var.default_tags

  depends_on = [module.network] # le NAT doit être routé AVANT le boot pour dnf
}

############################################################
# 5. S3 : un module par bucket (for_each sur le module)
############################################################
resource "random_id" "bucket_suffix" {
  byte_length = 4 # noms S3 uniques au niveau mondial
}



