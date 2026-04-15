# --- compute.tf (SOLO ROLES IAM) ---
# Hemos borrado el recurso "aws_instance" porque ahora lo gestiona el ASG en asg.tf

# 1. Definir el Rol de IAM (El "carnet de identidad" para el servidor)
resource "aws_iam_role" "ec2_efs_role" {
  name = "${var.project_name}-ec2-efs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "${var.project_name}-IAM-Role"
  }
}

# 2. Adjuntar la política de permisos de EFS al Rol
# Esto le da permiso para leer/escribir en Amazon EFS.
resource "aws_iam_role_policy_attachment" "efs_attachment" {
  role       = aws_iam_role.ec2_efs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"
}

# 3. Crear el Perfil de Instancia
# Es el "contenedor" del rol que se le puede "pegar" a un servidor EC2.
# Este perfil es el que usa el Launch Template en asg.tf
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_efs_role.name
}