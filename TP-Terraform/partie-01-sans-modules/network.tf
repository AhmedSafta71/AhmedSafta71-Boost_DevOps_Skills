############################################################
# Réseau : 1 subnet public + 1 subnet privé
############################################################
resource "aws_subnet" "public" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false # IP publique donnée explicitement à l'instance

  tags = {
    Name = "${local.prefix}_subnet_public"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = data.aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${local.prefix}_subnet_private"
    Tier = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.prefix}_rt_public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.aws_nat_gateway.main.id
  }

  tags = {
    Name = "${local.prefix}_rt_private"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
