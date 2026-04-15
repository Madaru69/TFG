# 1. Crear la VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-VPC"
    Enviroment = "DevOps-Lab"
  }
}


# 2. Crear el Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-IGW"
  }
}

# Subred Privada Auxiliar (Solo para cumplir requisito de RDS de 2 AZs)
resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.aws_region}b" # Nota la "b" al final

  tags = {
    Name = "${var.project_name}-Private-Subnet-B"
  }
}