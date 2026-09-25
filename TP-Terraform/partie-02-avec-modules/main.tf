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
# 2. Security Groups
############################################################
module "security" {
  source = "./modules/security"

  prefix         = local.prefix
  suffix         = local.suffix
  vpc_id         = data.aws_vpc.main.id
  admin_ssh_cidr = local.admin_ssh_cidr
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
module "ec2_docker" {
  source = "./modules/ec2_instance"

  name                        = "${local.prefix}_ec2_docker${local.suffix}"
  ebs_name                    = "${local.prefix}_ebs_docker${local.suffix}"
  role_tag                    = "public-docker"
  ami_id                      = data.aws_ssm_parameter.al2023.insecure_value
  instance_type               = var.instance_type
  subnet_id                   = module.network.public_subnet_id
  security_group_ids          = [module.security.public_sg_id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.admin.key_name
  iam_instance_profile        = data.aws_iam_instance_profile.ssm.name
  user_data                   = file("${path.module}/user_data/docker.sh")
  http_put_response_hop_limit = 2 # nécessaire pour les conteneurs Docker
  root_volume_size            = var.root_volume_size
  default_tags                = var.default_tags

  depends_on = [module.network] # route vers l'IGW prête avant le boot
}

module "ec2_nodejs" {
  source = "./modules/ec2_instance"

  name                        = "${local.prefix}_ec2_nodejs${local.suffix}"
  ebs_name                    = "${local.prefix}_ebs_nodejs${local.suffix}"
  role_tag                    = "private-nodejs"
  ami_id                      = data.aws_ssm_parameter.al2023.insecure_value
  instance_type               = var.instance_type
  subnet_id                   = module.network.private_subnet_id
  security_group_ids          = [module.security.private_sg_id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.admin.key_name
  iam_instance_profile        = data.aws_iam_instance_profile.ssm.name
  user_data                   = file("${path.module}/user_data/nodejs.sh")
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

module "s3" {
  source   = "./modules/s3_secure_bucket"
  for_each = toset(var.s3_bucket_ids)

  bucket_name = "${local.bucket_prefix}-s3-${each.key}${local.bucket_suffix}-${random_id.bucket_suffix.hex}"
  name_tag    = "${local.prefix}_s3_${each.key}${local.suffix}"
}

############################################################
# 6. Arrêt 19h / démarrage 9h : Lambda + EventBridge Scheduler
#    (rôles EXISTANTS passés en entrée)
############################################################
module "lambda_scheduler" {
  source = "./modules/lambda_scheduler"

  prefix             = local.prefix
  suffix             = local.suffix
  source_file        = "${path.module}/lambda/ec2_scheduler.py"
  build_dir          = "${path.module}/.build"
  lambda_role_arn    = data.aws_iam_role.lambda_scheduler.arn
  scheduler_role_arn = data.aws_iam_role.scheduler.arn
  instance_ids       = [module.ec2_docker.id, module.ec2_nodejs.id]
  log_retention_days = var.log_retention_days
  start_expression   = var.start_schedule_expression
  stop_expression    = var.stop_schedule_expression
  timezone           = var.schedule_timezone
}
