
# ---------------- Sécurité ----------------
resource "aws_security_group" "app" {
  name   = "glpi-app-sg"
  vpc_id = data.aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [locals.allowed_ssh_cidr]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [locals.allowed_ssh_cidr]
  }
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [locals.allowed_ssh_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# La BDD n'accepte QUE le trafic venant du SG du serveur applicatif
resource "aws_security_group" "db" {
  name   = "glpi-db-sg"
  vpc_id = data.aws_vpc.main.id

  ingress {
    description     = "MariaDB depuis le serveur applicatif"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
  ingress {
    description     = "SSH via le serveur applicatif (bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
