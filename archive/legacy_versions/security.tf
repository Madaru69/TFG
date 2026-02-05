# --- security.tf ---

# 1. Security Group para el Servidor Web (EC2)
# Este grupo protege a la instancia donde corre Moodle y Apache.
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-Web-SG"
  description = "Permitir trafico HTTP solo desde el ALB y SSH para administracion"
  vpc_id      = aws_vpc.main_vpc.id

  # --- REGLAS DE ENTRADA (INGRESS) ---

  # Regla HTTP (Puerto 80) - [CAMBIO CLAVE AQUÍ]
  # YA NO permitimos el tráfico directo de internet (0.0.0.0/0).
  # SOLO permitimos tráfico que venga del Security Group del Balanceador de Carga (ALB).
  # Esto obliga a que todo el tráfico de usuarios pase primero por el "recepcionista" (ALB).
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    # Terraform busca el ID del SG del ALB (definido en alb.tf)
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Regla SSH (Puerto 22)
  # Se restringe el acceso para gestión remota segura
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr] 
  }

  # --- REGLAS DE SALIDA (EGRESS) ---

  # Permitimos que el servidor salga a internet para todo (necesario para apt-get, git clone, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 significa todos los protocolos
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-Web-SG"
  }
}


# 2. Security Group para la Base de Datos (RDS)
# Protege tu MySQL. Es muy estricto.
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-RDS-SG"
  description = "Permitir trafico MySQL solo desde el Servidor Web"
  vpc_id      = aws_vpc.main_vpc.id

  # Solo permite entrar al puerto 3306 (MySQL) si vienes del Security Group del Servidor Web.
  # ¡Nadie más puede entrar!
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # Normalmente la BD no necesita salir a internet, pero por si acaso AWS necesita conexiones internas.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-RDS-SG"
  }
}


# 3. Security Group para el Almacenamiento Compartido (EFS)
# Protege tu disco de red.
resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-EFS-SG"
  description = "Permitir trafico NFS solo desde el Servidor Web"
  vpc_id      = aws_vpc.main_vpc.id

  # Solo permite entrar al puerto 2049 (NFS) si vienes del Security Group del Servidor Web.
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-EFS-SG"
  }
}