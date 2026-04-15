# Revisión Técnica del TFG: Infraestructura Cloud Moodle (ASIR)

**Autor de la revisión:** Antigravity  
**Fecha:** 2026-02-03  
**Objetivo:** Análisis de arquitectura, código Terraform y validación de requisitos para TFG de ASIR.

---

## 1. Resumen Ejecutivo
El proyecto presenta una **arquitectura sólida y moderna** para un nivel de ASIR. Demuestra un dominio claro de los conceptos de *Cloud Computing* (AWS) e *Infrastructure as Code* (Terraform). La transición propuesta de arquitectura monolítica a escalable (High Availability) está bien planteada.

Sin embargo, he detectado **un punto crítico de automatización** que impediría que el despliegue funcione "con un solo click", así como varias recomendaciones de seguridad que elevarían la nota del proyecto.

---

## 2. Puntos Fuertes
*   **Arquitectura de Alta Disponibilidad:** El uso correcto de Zonas de Disponibilidad (AZs) redundantes para Subredes, ASG y EFS es excelente.
*   **Separiación de Capas:** La distinción entre Seguridad de Red (Security Groups en capas) está muy bien implementada (Internet -> ALB -> EC2 -> RDS/EFS).
*   **FinOps:** La elección de instancias `t3.micro` y el sistema de etiquetado (`tags`) demuestran madurez profesional.
*   **Chaos Testing:** Incluir una guía de "Pruebas de Caos" es un gran valor añadido que demuestra que el sistema no solo se "construye", sino que se **valida**.

---

## 3. Hallazgo Crítico: Automatización de la Base de Datos
**Problema:**
En `asg.tf`, la *Golden AMI* se despliega tal cual. Sin embargo, Terraform crea una nueva instancia RDS (`aws_db_instance.moodle_db`) que tendrá un **Endpoint (DNS)** nuevo y aleatorio cada vez que se crea la infraestructura.
¿Cómo sabe la instancia EC2 (Moodle) cuál es la IP de la base de datos?
Actualmente, el `user_data` solo monta el EFS, pero **no actualiza el archivo `config.php` de Moodle**. Esto significa que Moodle intentará conectarse a la IP que tenía cuando creaste la AMI, fallando al iniciar.

**Solución Recomendada:**
Inyectar el endpoint de la RDS en el `user_data` del Launch Template (`asg.tf`).
Debes añadir lógica para sustituir la dirección de la BD en el archivo de configuración.

**Código sugerido para `asg.tf`:**
```hcl
user_data = base64encode(<<-EOF
  #!/bin/bash
  # 1. Montaje de EFS (Correcto)
  mkdir -p /var/www/html/moodle/moodledata
  mount -t nfs4 ... (tu comando mount) ...
  
  # 2. [NUEVO] Configuración Dinámica de Base de Datos
  # Asumiendo que config.php ya existe en la AMI
  CD_MOODLE="/var/www/html/moodle"
  DB_HOST="${aws_db_instance.moodle_db.address}" # Terraform inyecta esto aquí
  
  # Usamos sed para reemplazar la host antigua por la nueva
  sed -i "s/dbhost\s*=\s*'.*';/dbhost = '$DB_HOST';/g" $CD_MOODLE/config.php
  
  # 3. Permisos y Reinicio
  chown -R www-data:www-data /var/www/html/moodle
  systemctl restart apache2
  EOF
)
```

---

## 4. Mejoras de Seguridad Recomendadas

### A. Ubicación de los Servidores Web (EC2)
*   **Estado Actual:** Las instancias EC2 están en las **Subredes Públicas** (`public_subnet_a/b`). Tienen IP pública y están expuestas directamente (si el SG lo permite).
*   **Recomendación:** En una arquitectura ideal de 3 capas, los servidores web deben ir en **Subredes Privadas**. El acceso desde internet solo debe llegar al ALB.
*   **Nota:** Esto requiere un **NAT Gateway** para que las instancias puedan descargar actualizaciones, lo que encarece el proyecto ($$$). Para un TFG está bien justificarlo: *"Por costes mantenemos EC2 en pública, pero restringimos el tráfico con Security Groups"*. **Es importante que menciones esto en la memoria.**

### B. Acceso SSH (Puerto 22)
*   **Estado Actual:** `0.0.0.0/0` en `variables.tf`.
*   **Riesgo:** Dejar el puerto 22 abierto a todo internet es una mala práctica.
*   **Mejora 1:** Restringir a tu IP (Mi IP).
*   **Mejora 2 (Pro):** Usar **AWS Systems Manager (Session Manager)** y cerrar el puerto 22 completamente. Esto es muy bien valorado en proyectos de Cloud moderno.

### C. Cifrado (HTTPS)
*   **Estado Actual:** Solo HTTP (Puerto 80).
*   **Recomendación:** Para un TFG, desplegar certificados SSL puede ser complejo (requiere dominio real). Basta con que menciones en las "Líneas Futuras" que el siguiente paso sería implementar **AWS ACM (Certificate Manager)** en el ALB para habilitar HTTPS (443).

---

## 5. Calidad de Código (Clean Code)

### A. Outputs
Te falta "ver" la dirección de la base de datos por si necesitas entrar manualmente.
Crea un archivo `outputs.tf` o añádelo a `alb.tf`:
```hcl
output "db_endpoint" {
  description = "Endpoint de conexión a RDS MySQL"
  value       = aws_db_instance.moodle_db.address
}
```

### B. Estandarización
En `asg.tf`, usas `max_size = 4` y `min_size = 2`. Asegúrate de que tu cuenta de AWS tenga límite (vCPU limits) suficiente, aunque para t3.micro no habrá problema.

---

## 6. Conclusión
El proyecto está **aprobado y bien encaminado**. Si corriges la inyección de la base de datos (Punto 3), tendrás un sistema totalmente automatizado. La documentación de *Chaos Testing* es un punto brillante. ¡Buen trabajo!
