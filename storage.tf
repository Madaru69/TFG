# --- storage.tf (Corregido con los nuevos nombres de Security Groups) ---

# --- SECCIÓN 1: Base de Datos (RDS) ---

# 1. Grupo de Subredes para RDS (Le dice a RDS qué subredes privadas puede usar)
resource "aws_db_subnet_group" "moodle_db_subnet_group" {
  name       = "${var.project_name}-db-subnet-group"
  # RDS necesita al menos dos subredes en distintas zonas para alta disponibilidad
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]

  tags = {
    Name = "Moodle DB Subnet Group"
  }
}

# 2. La Instancia de Base de Datos (MySQL)
resource "aws_db_instance" "moodle_db" {
  allocated_storage      = 20           # 20 GB de espacio
  db_name                = var.db_name  # Nombre de la BD dentro de MySQL (ej: moodle)
  engine                 = "mysql"
  engine_version         = "8.0"        # Versión compatible con Moodle
  instance_class         = "db.t3.micro" # Tamaño del servidor (el más barato)
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true         # Para el lab, borramos sin copia de seguridad final
  db_subnet_group_name   = aws_db_subnet_group.moodle_db_subnet_group.name
  
  # [NOTA FINOPS] En un entorno de Producción real, este valor DEBE ser 'true'.
  # Se mantiene en 'false' para el laboratorio académico debido al coste (aprox. x2).
  multi_az               = false 
  
  # [CORRECCIÓN AQUÍ] Usamos el nombre nuevo del SG específico para RDS
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "${var.project_name}-RDS"
  }
}


# --- SECCIÓN 2: Almacenamiento de Archivos Compartido (EFS) ---

# 3. El Sistema de Archivos EFS (El "disco duro" en la nube)
resource "aws_efs_file_system" "moodle_efs" {
  creation_token = "${var.project_name}-EFS"
  encrypted      = true # Cifrado por seguridad

  tags = {
    Name = "${var.project_name}-EFS"
  }
}

# 4. Puntos de Montaje (Mount Targets)
# Son los "enchufes" de red en las subredes privadas donde conectaremos el disco.
# Necesitamos uno en cada zona de disponibilidad donde haya servidores.

# Mount Target en la Subred Privada A
resource "aws_efs_mount_target" "efs_mt_a" {
  file_system_id  = aws_efs_file_system.moodle_efs.id
  subnet_id       = aws_subnet.private_subnet.id
  
  # [CORRECCIÓN AQUÍ] Usamos el nombre nuevo del SG específico para EFS
  security_groups = [aws_security_group.efs_sg.id]
}

# Mount Target en la Subred Privada B (Para alta disponibilidad)
resource "aws_efs_mount_target" "efs_mt_b" {
  file_system_id  = aws_efs_file_system.moodle_efs.id
  subnet_id       = aws_subnet.private_subnet_b.id
  
  # [CORRECCIÓN AQUÍ] Usamos el nombre nuevo del SG específico para EFS
  security_groups = [aws_security_group.efs_sg.id]
}