# --- main.tf (Red ampliada para Alta Disponibilidad) ---

# 1. VPC (Sin cambios)
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name       = "${var.project_name}-VPC"
    Enviroment = "DevOps-Lab"
  }
}

# 2. Internet Gateway (Sin cambios)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}

# --- 3. Subredes ---

# Subred Pública A (ANTES: "public_subnet". Le cambiamos el nombre para aclarar)
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr # Usamos la variable original
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-Public-Subnet-A"
  }
}

# [NUEVO] Subred Pública B (Necesaria para el futuro Balanceador de Carga)
resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_b # Usamos la nueva variable
  availability_zone       = "${var.aws_region}b" # Zona B
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-Public-Subnet-B"
  }
}


# Subred Privada A (Sin cambios)
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.private_subnet_cidr
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.project_name}-Private-Subnet-A"
  }
}

# Subred Privada B (Sin cambios)
resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.private_subnet_b_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-Private-Subnet-B"
  }
}

# --- 4. Enrutamiento Público ---

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-Public-RT"
  }
}

# Asociación para la Subred Pública A (Actualizamos la referencia al nuevo nombre)
resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

# [NUEVO] Asociación para la Subred Pública B (Conectarla a Internet también)
resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}