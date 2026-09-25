############################################################
# Security Groups (moindre privilège, egress restreint)
#    Admin --22--> Public(bastion) --22--> Privé
#    Sortie : HTTPS uniquement (dnf, Docker Hub, endpoints SSM)
############################################################
resource "aws_security_group" "public" {
  name        = "${local.prefix}_sg_public"
  description = "Serveur public Docker - SSH admin uniquement"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "${local.prefix}_sg_public"
  }
}

resource "aws_security_group" "private" {
  name        = "${local.prefix}_sg_private"
  description = "Serveur prive Nodejs - SSH depuis le bastion uniquement"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "${local.prefix}_sg_private"
  }
}

  # --- Public : entrées ---
  # resource "aws_vpc_security_group_ingress_rule" "public_ssh_admin" {
  #   security_group_id = aws_security_group.public.id
  #   description       = "SSH depuis IP admin"
  #   cidr_ipv4         = local.admin_ssh_cidr
  #   ip_protocol       = "tcp"
  #   from_port         = 22
  #   to_port           = 22

  #   tags = { Name = "${local.prefix}_sgr_public_ssh_admin" }
  # }

# --- Public : sorties ---
resource "aws_vpc_security_group_egress_rule" "public_https" {
  security_group_id = aws_security_group.public.id
  description       = "HTTPS sortant - dnf Docker Hub SSM"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443

  tags = { Name = "${local.prefix}_sgr_public_https_out" }
}

# resource "aws_vpc_security_group_egress_rule" "public_ssh_to_private" {
#   security_group_id            = aws_security_group.public.id
#   description                  = "SSH rebond vers serveur prive"
#   referenced_security_group_id = aws_security_group.private.id
#   ip_protocol                  = "tcp"
#   from_port                    = 22
#   to_port                      = 22

#   tags = { Name = "${local.prefix}_sgr_public_ssh_to_private" }
# }

# --- Privé : entrées ---
# resource "aws_vpc_security_group_ingress_rule" "private_ssh_from_bastion" {
#   security_group_id            = aws_security_group.private.id
#   description                  = "SSH depuis le SG du serveur public uniquement"
#   referenced_security_group_id = aws_security_group.public.id
#   ip_protocol                  = "tcp"
#   from_port                    = 22
#   to_port                      = 22

#   tags = { Name = "${local.prefix}_sgr_private_ssh_from_bastion" }
# }

# --- Privé : sorties ---
resource "aws_vpc_security_group_egress_rule" "private_https" {
  security_group_id = aws_security_group.private.id
  description       = "HTTPS sortant via NAT - dnf et SSM"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443

  tags = { Name = "${local.prefix}_sgr_private_https_out" }
}
