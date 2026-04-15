# --- asg.tf (Estrategia de Computación Efímera) ---

# 1. Launch Template: Definición técnica de los nodos de cómputo
resource "aws_launch_template" "moodle_lt" {
  name_prefix   = "${var.project_name}-LT-"
  # Insumo: Golden AMI con pre-instalación de Moodle
  image_id      = var.ami_id
  instance_type = var.instance_type

  # Perfil IAM: Garantiza acceso seguro a Amazon EFS
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # Security Group: Restricción de tráfico al nivel del Host
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # User Data: Configuración de "Última Milla" (Montaje de volúmenes compartidos)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # 1. Asegurar punto de montaje para persistencia
              mkdir -p /var/www/html/moodle/moodledata
              # 2. Procedimiento de montaje NFSv4 (EFS)
              mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${aws_efs_file_system.moodle_efs.dns_name}:/ /var/www/html/moodle/moodledata
              # 3. Ajuste de permisos para el usuario www-data
              chown -R www-data:www-data /var/www/html/moodle
              # 4. Reinicio de servicio para validación de cambios
              systemctl restart apache2
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-ASG-Instance"
      Environment = "Production-Simulation"
    }
  }
}

# 2. Auto Scaling Group: Gestión de la disponibilidad y resiliencia
resource "aws_autoscaling_group" "moodle_asg" {
  name                = "${var.project_name}-ASG"
  # Queremos ALTA DISPONIBILIDAD: Mínimo 2 servidores siempre.
  desired_capacity    = 2
  
  # [CORRECCIÓN AQUÍ] Los nombres correctos son min_size y max_size
  max_size            = 4 # Podría crecer hasta 4
  min_size            = 2 # Nunca menos de 2

  # Desplegar los servidores en las DOS subredes públicas (Zona A y Zona B)
  vpc_zone_identifier = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]

  # Conectar automáticamente los nuevos servidores al Target Group del ALB
  target_group_arns = [aws_lb_target_group.alb_tg.arn]

  # Usar la plantilla que acabamos de definir arriba
  launch_template {
    id      = aws_launch_template.moodle_lt.id
    version = "$Latest"
  }

  # Configuración de Salud
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Etiqueta para los servidores creados
  tag {
    key                 = "Name"
    value               = "${var.project_name}-ASG-Server"
    propagate_at_launch = true
  }

  # Esperar a que se destruya el servidor viejo antes de crear este grupo
  depends_on = [aws_efs_mount_target.efs_mt_a, aws_efs_mount_target.efs_mt_b]
}