# --- storage.tf (Persistencia) ---

# --- EFS (Archivos) ---
resource "aws_efs_file_system" "moodle_efs" {
  creation_token = "${var.project_name}-efs"
  encrypted      = true
  tags           = { Name = "${var.project_name}-efs" }
}

resource "aws_efs_mount_target" "efs_mt_a" {
  file_system_id  = aws_efs_file_system.moodle_efs.id
  subnet_id       = aws_subnet.private_subnet_a.id # Montaje en Zona A
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "efs_mt_b" {
  file_system_id  = aws_efs_file_system.moodle_efs.id
  subnet_id       = aws_subnet.private_subnet_b.id # Montaje en Zona B
  security_groups = [aws_security_group.efs_sg.id]
}

# --- RDS (Base de Datos) ---
resource "aws_db_subnet_group" "moodle_db_sg" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

resource "aws_db_instance" "moodle_db" {
  allocated_storage      = 20
  db_name                = var.db_name
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.moodle_db_sg.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = { Name = "${var.project_name}-rds" }
}

# --- [BYTEMIND SRE] Access Point para Moodle ---
# Esto garantiza que cualquier archivo en EFS sea propiedad de www-data (UID 33)
resource "aws_efs_access_point" "moodle_ap" {
  file_system_id = aws_efs_file_system.moodle_efs.id

  posix_user {
    gid = 33 
    uid = 33 
  }

  root_directory {
    path = "/moodle_data"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = "775"
    }
  }

  tags = {
    Name = "${var.project_name}-efs-ap"
  }
}
