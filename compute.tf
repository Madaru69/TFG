# --- compute.tf (Solo Roles IAM) ---

# Rol para que las EC2 puedan acceder a servicios AWS
resource "aws_iam_role" "ec2_efs_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Permiso para EFS
resource "aws_iam_role_policy_attachment" "efs_attachment" {
  role       = aws_iam_role.ec2_efs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"
}

# [BYTEMIND SRE] Permiso para SSM (Administración y Debugging)
resource "aws_iam_role_policy_attachment" "ssm_attachment" {
  role       = aws_iam_role.ec2_efs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Perfil de Instancia
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_efs_role.name
}
