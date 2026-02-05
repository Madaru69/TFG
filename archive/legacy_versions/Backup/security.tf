# --- 1. Security Group para el Servidor Web (PÚBLICO) ---
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-Web-SG"
  description = "Permitir trafico HTTP, HTTPS y SSH"
  vpc_id      = aws_vpc.main_vpc.id

  # Entrada: HTTP (Todo el mundo)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Entrada: HTTPS (Todo el mundo - Para el futuro SSL)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Entrada: SSH (aqui abierto para facilitar pruebas iniciales)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Salida: Todo permitido (para que el servidor pueda descargar actualizaciones)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-Web-SG"
  }
}

# --- 2. Security Group para Datos (PRIVADO - RDS & EFS) ---
resource "aws_security_group" "data_sg" {
  name        = "${var.project_name}-Data-SG"
  description = "Permitir trafico SOLO desde el Servidor Web"
  vpc_id      = aws_vpc.main_vpc.id

  # Entrada MySQL: SOLO desde el Security Group Web
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # Referencia cruzada
  }

  # Entrada NFS (EFS): SOLO desde el Security Group Web
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  tags = {
    Name = "${var.project_name}-Data-SG"
  }
}