############################################################
# Admin --22--> Public(bastion) --22--> Privé
# Sortie : HTTPS uniquement (dnf, Docker Hub, endpoints SSM)
############################################################
resource "aws_security_group" "public" {
  name        = "${var.prefix}_sg_public${var.suffix}"
  description = "Serveur public Docker - SSH admin uniquement"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.prefix}_sg_public${var.suffix}"
  }
}

resource "aws_security_group" "private" {
  name        = "${var.prefix}_sg_private${var.suffix}"
  description = "Serveur prive Nodejs - SSH depuis le bastion uniquement"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.prefix}_sg_private${var.suffix}"
  }
}


  # --- Public : entrées ---
  resource "aws_vpc_security_group_ingress_rule" "public_ssh_admin" {
    security_group_id = aws_security_group.public.id
    description       = "SSH depuis IP admin"
    cidr_ipv4         = local.admin_ssh_cidr
    ip_protocol       = "tcp"
    from_port         = 22
    to_port           = 22

    tags = { Name = "${local.prefix}_sgr_public_ssh_admin" }
  }

    resource "aws_vpc_security_group_ingress_rule" "public_ssh_admin" {
    security_group_id = aws_security_group.private.id
    description       = "SSH depuis IP admin"
    cidr_ipv4         = local.admin_ssh_cidr
    ip_protocol       = "tcp"
    from_port         = 22
    to_port           = 22

    tags = { Name = "${local.prefix}_sgr_private_ssh_admin" }
  }


