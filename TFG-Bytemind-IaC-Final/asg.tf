# --- asg.tf (Auto Scaling Group) ---

# 1. Plantilla de Lanzamiento (El plano de los servidores)
resource "aws_launch_template" "moodle_lt" {
  name_prefix   = "${var.project_name}-LT-"
  
  # TU AMI (Imagen Maestra) - Asegúrate de que esta imagen existe en tu cuenta
  image_id      = "ami-0216c40e040e8230b" 
  
  # Tipo de instancia (t3.micro para la región España)
  instance_type = var.instance_type
  
  # Perfil IAM para poder montar el EFS
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # Security Group (Solo tráfico desde el ALB)
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # User Data V10: Sincronización Universal Bytemind
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # 1. Logs para auditoría y rescate
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              
              echo "--- [RESCATE MÁXIMO] Alineando Moodle con la Infraestructura Nueva ---"
              systemctl stop apache2
              systemctl stop mysql || true
              systemctl stop mariadb || true
              
              # 2. Preparar Almacenamiento
              MOODLE_DATA="/var/www/moodledata"
              mkdir -p $MOODLE_DATA
              mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${aws_efs_file_system.moodle_efs.dns_name}:/ $MOODLE_DATA
              
              # 3. ESPERAR A LA BASE DE DATOS (Critical)
              echo "Esperando a que el RDS (${aws_db_instance.moodle_db.address}) esté listo..."
              until timeout 1 bash -c "cat < /dev/null > /dev/tcp/${aws_db_instance.moodle_db.address}/3306"; do
                  echo "RDS no responde en el puerto 3306. Reintentando en 5s..."
                  sleep 5
              done
              echo "¡RDS Detectado!"

              # 4. Sincronización God-Mode (V18) - DESBLOQUEO DE INSTALACIÓN
              echo "--- [BYTEMIND] Iniciando Parcheo V18 ---"
              
              if [ -f "/var/www/html/moodle/config.php" ]; then
                  CONFIG_FILE="/var/www/html/moodle/config.php"
              elif [ -f "/var/www/html/config.php" ]; then
                  CONFIG_FILE="/var/www/html/config.php"
              else
                  CONFIG_FILE=$(find /var/www/html -name config.php | grep -v "moodledata" | head -n 1)
              fi
              
              echo "--- [BYTEMIND] Config.php localizado en: $CONFIG_FILE ---"

              if [ -n "$CONFIG_FILE" ]; then
                  # USAMOS CONCATENACIÓN DE COMILLAS PARA EVITAR QUE BASH O TERRAFORM SE COMAN EL $
                  sed -i "s|.*dbhost.*|"'\$CFG->'"dbhost    = '${aws_db_instance.moodle_db.address}';|g" $CONFIG_FILE
                  sed -i "s|.*wwwroot.*|"'\$CFG->'"wwwroot   = 'http://${aws_lb.app_alb.dns_name}';|g" $CONFIG_FILE
                  sed -i "s|.*dataroot.*|"'\$CFG->'"dataroot   = '$MOODLE_DATA';|g" $CONFIG_FILE
                  sed -i "s|.*dbname.*|"'\$CFG->'"dbname     = '${var.db_name}';|g" $CONFIG_FILE
                  sed -i "s|.*dbuser.*|"'\$CFG->'"dbuser     = '${var.db_username}';|g" $CONFIG_FILE
                  sed -i "s|.*dbpass.*|"'\$CFG->'"dbpass     = '${var.db_password}';|g" $CONFIG_FILE
                  
                  # Asegurar bypass de IP para instalación (V18)
                  if grep -q "install_ip_check" $CONFIG_FILE; then
                      sed -i "s|.*install_ip_check.*|"'\$CFG->'"install_ip_check = false;|g" $CONFIG_FILE
                  else
                      sed -i "/dbhost/a "'\$CFG->'"install_ip_check = false;" $CONFIG_FILE
                  fi

                  echo "--- [BYTEMIND] Parches V18 aplicados (Instalación desbloqueada). ---"
              fi

              # 5. Permisos y Estructura Legacy
              MOODLE_WEB_DIR=$(dirname $CONFIG_FILE)
              chown -R www-data:www-data $MOODLE_WEB_DIR
              
              if [ ! -L "$MOODLE_WEB_DIR/moodledata" ]; then
                  ln -s $MOODLE_DATA $MOODLE_WEB_DIR/moodledata
              fi
              
              chown -R www-data:www-data $MOODLE_DATA
              chmod -R 777 $MOODLE_DATA
              
              # 6. Purga de Caches (CRITICO)
              echo "--- [BYTEMIND] Purgando caches nucleares... ---"
              rm -rf $MOODLE_DATA/cache/*
              rm -rf $MOODLE_DATA/localcache/*
              rm -rf $MOODLE_DATA/muc/*
              
              # 7. Reinicio Maestro
              echo "--- [BYTEMIND] Reiniciando Apache... ---"
              systemctl restart apache2
              echo "--- [BYTEMIND FINISH V18] ---"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-ASG-Instance"
      ForceUpdate = "FINAL-RECOVERY-V18-BYPASS"
    }
  }
}

# 2. Grupo de Auto-Escalado (El gestor de la flota)
resource "aws_autoscaling_group" "moodle_asg" {
  name                = "${var.project_name}-ASG"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  target_group_arns   = [aws_lb_target_group.alb_tg.arn]

  launch_template {
    id      = aws_launch_template.moodle_lt.id
    version = "$Latest"
  }

  # ESTRATEGIA DE ROTACIÓN (PHASE 3 - HA)
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ASG-Server"
    propagate_at_launch = true
  }

  tag {
    key                 = "Phase"
    value               = "3-HighAvailability"
    propagate_at_launch = true
  }

  depends_on = [
    aws_efs_mount_target.efs_mt_a, 
    aws_efs_mount_target.efs_mt_b,
    aws_db_instance.moodle_db
  ]
}
