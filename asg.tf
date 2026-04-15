# --- asg.tf (Auto Scaling Group) ---

# 1. Plantilla de Lanzamiento (Definición Base de Capacidad de Cómputo)
resource "aws_launch_template" "moodle_lt" {
  name_prefix = "${var.project_name}-LT-"

  # Especificación de la Amazon Machine Image (AMI) base pre-configurada para el despliegue de Moodle
  image_id = "ami-0216c40e040e8230b"

  # Tipo de instancia EC2 optimizada para la región objetivo
  instance_type = var.instance_type

  # Perfil IAM para poder montar el EFS
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  # Security Group (Solo tráfico desde el ALB)
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # User Data: Script de inicialización (Bootstrap) para auto-configuración y enganche a EFS/RDS
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # 1. Configuración de logs de inicialización para auditoría (Cloud-init)
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              
              echo "--- [INIT] Alineando servicios web con la nueva infraestructura IaC ---"
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

              # 4. Sincronización de configuración base de Moodle (config.php)
              echo "--- [INIT] Configurando parámetros de conexión a RDS y EFS ---"
              
              if [ -f "/var/www/html/moodle/config.php" ]; then
                  CONFIG_FILE="/var/www/html/moodle/config.php"
              elif [ -f "/var/www/html/config.php" ]; then
                  CONFIG_FILE="/var/www/html/config.php"
              else
                  CONFIG_FILE=$(find /var/www/html -name config.php | grep -v "moodledata" | head -n 1)
              fi
              
              echo "--- [INIT] Config.php localizado en: $CONFIG_FILE ---"

              if [ -n "$CONFIG_FILE" ]; then
                  # USAMOS CONCATENACIÓN DE COMILLAS PARA EVITAR QUE BASH O TERRAFORM SE COMAN EL $
                  sed -i "s|.*dbhost.*|"'\$CFG->'"dbhost    = '${aws_db_instance.moodle_db.address}';|g" $CONFIG_FILE
                  sed -i "s|.*wwwroot.*|"'\$CFG->'"wwwroot   = 'http://${aws_lb.app_alb.dns_name}';|g" $CONFIG_FILE
                  sed -i "s|.*dataroot.*|"'\$CFG->'"dataroot   = '$MOODLE_DATA';|g" $CONFIG_FILE
                  sed -i "s|.*dbname.*|"'\$CFG->'"dbname     = '${var.db_name}';|g" $CONFIG_FILE
                  sed -i "s|.*dbuser.*|"'\$CFG->'"dbuser     = '${var.db_username}';|g" $CONFIG_FILE
                  sed -i "s|.*dbpass.*|"'\$CFG->'"dbpass     = '${var.db_password}';|g" $CONFIG_FILE
                  
                  # [FIX] DESACTIVAR SSL PROXY Y LOGIN HTTPS PARA EVITAR BUCLE DE REDIRECCIÓN
                  # Si el config.php antiguo traía esto activado, causará conflicto con el ALB HTTP.
                  sed -i "s|.*sslproxy.*|"'\$CFG->'"sslproxy   = 0;|g" $CONFIG_FILE
                  sed -i "s|.*loginhttps.*|"'\$CFG->'"loginhttps = 0;|g" $CONFIG_FILE
                  
                  # SI NO HAY BASE DE DATOS (Porque es infra nueva), mejor ocultar el config.php para que salga el instalador
                  # De lo contrario, Moodle intenta conectar, ve la DB vacía y explota (Error 500).
                  # mv $CONFIG_FILE $CONFIG_FILE.bak
                  # echo "--- [BYTEMIND] Config.php ocultado para forzar instalador (Database Reset) ---"

                  # Pero espera... si oculto el config.php, el usuario tendrá que reinstalar.
                  # Mejor opción: Dejar que el usuario vea el error 500 o...
                  # Intentar que Moodle repare la DB? No, eso es CLI.
                  
                  # VAMOS A POSTPONER ESTO Y PREGUNTAR AL USUARIO.
                  # Pero si quiere VERLO FUNCIONAR, el instalador es la prueba visual más fácil.
                  
              echo "--- [INIT] Configuración aplicada exitosamente. ---"
              fi

              # 5. Permisos y Estructura Legacy
              MOODLE_WEB_DIR=$(dirname $CONFIG_FILE)
              chown -R www-data:www-data $MOODLE_WEB_DIR
              
              if [ ! -L "$MOODLE_WEB_DIR/moodledata" ]; then
                  ln -s $MOODLE_DATA $MOODLE_WEB_DIR/moodledata
              fi
              
              # [OPTIMIZATION] Avoid changing permissions recursively on EFS to prevent Boot Storms
              # Just ensure the root mount point is owned by www-data
              chown www-data:www-data $MOODLE_DATA
              chmod 777 $MOODLE_DATA
              
              # 6. Invocación de Purga de Caches (Esencial para evitar corrupción de sesiones distribuidas)
              echo "--- [INIT] Limpiando directorios temporales y de caché de Moodle... ---"
              rm -rf $MOODLE_DATA/cache/*
              rm -rf $MOODLE_DATA/localcache/*
              rm -rf $MOODLE_DATA/muc/*
              
              # 7. Reinicio de servicio para aplicar de forma segura todo el setup
              echo "--- [INIT] Reiniciando servicio web (Apache2)... ---"
              systemctl restart apache2
              echo "--- [INIT] Bootstrap (Configuración Inicial) completado exitosamente ---"
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.project_name}-ASG-Instance"
      LaunchPhase = "Production-Deployment-V1"
    }
  }
}

# 2. Grupo de Auto-Escalado (Orquestador de Capacidad y Resiliencia)
resource "aws_autoscaling_group" "moodle_asg" {
  name                = "${var.project_name}-ASG"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  target_group_arns   = [aws_lb_target_group.alb_tg.arn]

  # Habilitación de métricas de telemetría para AWS CloudWatch
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  launch_template {
    id      = aws_launch_template.moodle_lt.id
    version = "$Latest"
  }

  # Configuración de Estrategia de Rotación Continua para Alta Disponibilidad (HA)
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  health_check_type         = "ELB"
  health_check_grace_period = 600

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

# 3. Política de Escalado Dinámico Orientada a Carga de CPU
resource "aws_autoscaling_policy" "moodle_cpu_policy" {
  name                   = "${var.project_name}-cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.moodle_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0 # Umbral Objetivo: Escalar horizontalmente si el uso promedio de CPU excede el 50%
  }
}

# 4. Política de Escalado Reactivo basado en Nivel de Red (ALB Request Count)
resource "aws_autoscaling_policy" "moodle_request_policy" {
  name                   = "${var.project_name}-request-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.moodle_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.app_alb.arn_suffix}/${aws_lb_target_group.alb_tg.arn_suffix}"
    }
    target_value = 100.0 # Umbral de tolerancia de peticiones por objetivo (Target) configurado para pruebas
  }
}
