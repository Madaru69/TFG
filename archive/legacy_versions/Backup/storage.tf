# --- 1. Sistema de Archivos EFS (Para moodledata) ---
resource "aws_efs_file_system" "moodle_efs" {
  creation_token = "moodle-efs"
  encrypted      = true

  tags = {
    Name = "${var.project_name}-EFS"
  }
}

# El "Mount Target" conecta el EFS a la Subred Privada
resource "aws_efs_mount_target" "efs_mt" {
  file_system_id  = aws_efs_file_system.moodle_efs.id
  subnet_id       = subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]
  security_groups = [aws_security_group.data_sg.id]
}

# --- 2. Base de Datos RDS (MySQL) ---

# Grupo de subredes para la DB (Necesario para RDS)
resource "aws_db_subnet_group" "moodle_db_subnet_group" {
  name       = "moodle-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.public_subnet.id]
  
  tags = {
    Name = "${var.project_name}-DB-Subnet-Group"
  }
}

resource "aws_db_instance" "moodle_db" {
  allocated_storage    = 15
  db_name              = "moodle"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "adminmoodle"
  password             = "PasswordSeguro123!"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true # Para poder borrarla rapido con destroy
  
  vpc_security_group_ids = [aws_security_group.data_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.moodle_db_subnet_group.name
  
  tags = {
    Name = "${var.project_name}-RDS"
  }
}