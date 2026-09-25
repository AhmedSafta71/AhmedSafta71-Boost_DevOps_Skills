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


# --- Public : sorties ---
resource "aws_vpc_security_group_egress_rule" "public_https" {
  security_group_id = aws_security_group.public.id
  description       = "HTTPS sortant - dnf Docker Hub SSM"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443

  tags = { Name = "${var.prefix}_sgr_public_https_out${var.suffix}" }
}



# --- Privé : sorties ---
resource "aws_vpc_security_group_egress_rule" "private_https" {
  security_group_id = aws_security_group.private.id
  description       = "HTTPS sortant via NAT - dnf et SSM"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443

  tags = { Name = "${var.prefix}_sgr_private_https_out${var.suffix}" }
}
