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

  # User Data V7: Supervivencia Extrema (Standard Senior Architect)
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # 1. Registro de logs para auditoría
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              
              echo "--- [BYTEMIND INICIO] Iniciando Recuperación de Instancia ---"
              systemctl stop apache2
              
              # 2. Instalación de utilidades rápida (NFS base)
              apt-get update
              apt-get install -y nfs-common binutils git
              
              # Intentar instalar efs-utils de forma ligera (muchas AMIs lo incluyen o tienen el repo)
              if ! command -v mount.efs &> /dev/null; then
                  echo "Instalación ligera de efs-utils fallida, procedemos con NFS standard para velocidad."
              fi

              # 3. Preparar rutas
              MOODLE_DATA="/var/www/moodledata"
              mkdir -p $MOODLE_DATA
              
              echo "--- [MONTAJE] Intentando conexión con EFS ---"
              # Intentamos montaje NFS tradicional si el helper falla (más rápido)
              # DNS: ${aws_efs_file_system.moodle_efs.dns_name}
              # AP: ${aws_efs_access_point.moodle_ap.id}
              mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,tls ${aws_efs_file_system.moodle_efs.dns_name}:/ $MOODLE_DATA || \
              mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${aws_efs_file_system.moodle_efs.dns_name}:/ $MOODLE_DATA
              
              # 4. Enlazar Moodle
              echo "Sincronizando rutas de Moodle..."
              rm -rf /var/www/html/moodle/moodledata
              ln -s $MOODLE_DATA /var/www/html/moodle/moodledata
              
              # 5. Sincronización Total de config.php (Standard Senior DBA)
              echo "--- [CONFIG] Sincronizando Moodle con la Infraestructura Actual ---"
              CONFIG_FILE="/var/www/html/moodle/config.php"
              
              if [ -f "$CONFIG_FILE" ]; then
                  # Host de BD (RDS)
                  sed -i "s/\$CFG->dbhost.*/\$CFG->dbhost    = '${aws_db_instance.moodle_db.address}';/" $CONFIG_FILE
                  # Nombre de BD
                  sed -i "s/\$CFG->dbname.*/\$CFG->dbname    = '${var.db_name}';/" $CONFIG_FILE
                  # Usuario de BD
                  sed -i "s/\$CFG->dbuser.*/\$CFG->dbuser    = '${var.db_username}';/" $CONFIG_FILE
                  # Contraseña de BD
                  sed -i "s/\$CFG->dbpass.*/\$CFG->dbpass    = '${var.db_password}';/" $CONFIG_FILE
                  # URL del Sitio (Alineación con el Balanceador)
                  # IMPORTANTE: Moodle es muy estricto con la URL de acceso
                  sed -i "s|\$CFG->wwwroot.*|\$CFG->wwwroot   = 'http://${aws_lb.app_alb.dns_name}';|" $CONFIG_FILE
                  
                  echo "Config.php sincronizado con éxito."
              else
                  echo "ADVERTENCIA: No se encontró config.php en la ruta estándar."
              fi

              # 6. Permisos Finales (Seguridad y Aplicación)
              chown -R www-data:www-data $MOODLE_DATA
              chown -R www-data:www-data /var/www/html/moodle
              chmod -R 775 $MOODLE_DATA
              
              # 7. Arranque de Servicios
              echo "Levantando servicios web..."
              systemctl start apache2
              echo "--- [BYTEMIND FIN] El sistema debería estar online ahora ---"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-ASG-Instance"
      Environment = "Production-Simulation"
      ForceUpdate = "v8-FULL-ALB-SYNC" 
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

  # [NUEVO] Forzar la rotación de instancias cuando cambie el Launch Template
  # Esto asegura que los cambios en user_data se apliquen a servidores nuevos
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50 # Mantener al menos 1 servidor vivo durante el cambio
    }
  }

  # Esperar a que se destruya el servidor viejo antes de crear este grupo
  depends_on = [aws_efs_mount_target.efs_mt_a, aws_efs_mount_target.efs_mt_b]
}