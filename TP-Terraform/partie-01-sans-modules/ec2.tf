############################################################
# Key pair (clé publique uniquement : la clé privée ne quitte jamais votre poste)
############################################################
resource "aws_key_pair" "admin" {
  key_name   = "${local.prefix}_keypair"
  public_key = file(pathexpand(var.ssh_public_key_path))

  tags = { Name = "${local.prefix}_keypair" }
}

############################################################
# EC2 : serveur 1 PUBLIC (Docker) + serveur 2 PRIVÉ (Node.js)
############################################################
resource "aws_instance" "docker" {
  ami                         = data.aws_ssm_parameter.al2023.insecure_value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.admin.key_name
  iam_instance_profile        = data.aws_iam_instance_profile.ssm.name
  user_data                   = file("${path.module}/user_data/docker.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 obligatoire
    http_put_response_hop_limit = 2          # nécessaire pour les conteneurs Docker
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  volume_tags = merge(var.default_tags, { Name = "${local.prefix}_ebs_docker" })

  tags = {
    Name = "${local.prefix}_ec2_docker"
    Role = "public-docker"
  }

  lifecycle {
    ignore_changes = [ami] # évite de recréer l'instance à chaque nouvelle AMI
  }

  depends_on = [aws_route_table_association.public]
}

resource "aws_instance" "nodejs" {
  ami                         = data.aws_ssm_parameter.al2023.insecure_value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private.id
  vpc_security_group_ids      = [aws_security_group.private.id]
  associate_public_ip_address = false
  key_name                    = aws_key_pair.admin.key_name
  iam_instance_profile        = data.aws_iam_instance_profile.ssm.name
  user_data                   = file("${path.module}/user_data/nodejs.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  volume_tags = merge(var.default_tags, { Name = "${local.prefix}_ebs_nodejs" })

  tags = {
    Name = "${local.prefix}_ec2_nodejs"
    Role = "private-nodejs"
  }

  lifecycle {
    ignore_changes = [ami]
  }

  # le NAT doit être routé AVANT le boot pour que dnf fonctionne
  depends_on = [aws_route_table_association.private]
}
