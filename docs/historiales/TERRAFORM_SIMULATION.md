# Simulación de Despliegue: `terraform apply`

Este documento desglosa paso a paso qué ocurre "bajo el capó" cuando ejecutas el comando `terraform apply` en tu proyecto.

![Arquitectura AWS Moodle](aws_architecture_moodle_1770106704809.png)

## Fase 1: Planificación (The Plan)
Terraform analiza tu código y lo compara con lo que hay en AWS (que al principio es nada).
Calcula el "grafo de dependencias" para saber en qué orden crear las cosas. Por ejemplo, sabe que no puede crear los servidores si no existe la red.

---

## Fase 2: Ejecución (Apply)

A continuación, verás una simulación de los logs que verías en tu terminal, con explicaciones de qué está pasando en cada bloque.

### Bloque A: Los Cimientos (VPC y Red)
```text
aws_vpc.main_vpc: Creating...
aws_vpc.main_vpc: Creation complete after 3s [id=vpc-0a1b2c3d]
aws_subnet.public_subnet_a: Creating...
aws_subnet.public_subnet_b: Creating...
aws_subnet.private_subnet: Creating...
aws_internet_gateway.igw: Creating...
...
```
**¿Qué sucede?**
Se crea el "datacenter virtual" (VPC). Se divide en subredes (habitaciones). Se enchufa el cable a internet (Internet Gateway).
*   *Tiempo estimado:* 10-20 segundos.

### Bloque B: La Seguridad (Security Groups)
```text
aws_security_group.alb_sg: Creating...
aws_security_group.web_sg: Creating...
aws_security_group.rds_sg: Creating...
aws_security_group.efs_sg: Creating...
```
**¿Qué sucede?**
Se crean los "firewalls virtuales". Terraform es muy listo y gestiona las dependencias circulares: crea los grupos vacíos primero y luego añade las reglas que permiten al Grupo Web hablar con el Grupo RDS.
*   *Tiempo estimado:* 5 segundos.

### Bloque C: La Capa de Datos (Lo más lento)
```text
aws_db_instance.moodle_db: Creating...
aws_efs_file_system.moodle_efs: Creating...
```
**¿Qué sucede?**
Aquí empieza la espera.
*   **RDS:** AWS está aprovisionando un servidor real, instalando MySQL 8.0 y configurando backups. Esto tarda mucho.
*   **EFS:** Se crea el sistema de archivos elástico.
*   *Tiempo estimado:* **5 a 10 minutos** (Paciencia aquí).

### Bloque D: Conectividad de Datos
```text
aws_efs_mount_target.efs_mt_a: Creating...
aws_efs_mount_target.efs_mt_b: Creating...
```
**¿Qué sucede?**
Una vez que el EFS (disco) y la VPC (red) existen, Terraform crea las "tarjetas de red" (Mount Targets) que permiten conectar el disco a las subredes privadas. Sin esto, los servidores no verían el disco.

### Bloque E: Balanceador y Preparación de Cómputo
```text
aws_lb.app_alb: Creating...
aws_lb_target_group.alb_tg: Creating...
aws_launch_template.moodle_lt: Creating...
```
**¿Qué sucede?**
*   **ALB:** Se despliega el "Recepcionista". AWS le asigna un nombre DNS público (ej: `tfg-alb-123.eu-south-2.elb.amazonaws.com`).
*   **Launch Template:** Se define la "receta" de los servidores: "Usar la AMI de Moodle, tipo t3.micro, y cuando arranques, ejecuta este script `user_data` para montar el EFS".

### Bloque F: El Despliegue Final (Auto Scaling)
```text
aws_autoscaling_group.moodle_asg: Creating...
```
**¿Qué sucede?**
El momento de la verdad. El Auto Scaling Group lee la plantilla y dice: "Necesito 2 servidores".
1.  Lanza `Instance-1` en Zona A.
2.  Lanza `Instance-2` en Zona B.
3.  Espera a que los servidores digan "Estoy listo" (Health Check).
4.  Tan pronto están listos, el ASG los registra en el Target Group del Balanceador.

---

## Fase 3: Resultado (Outputs)

```text
Apply complete! Resources: 24 added, 0 changed, 0 destroyed.

Outputs:
alb_dns_name = "tfg-bytemind-ALB-123456789.eu-south-2.elb.amazonaws.com"
```

**Estado Final:**
Tienes una infraestructura completa. Si copias ese DNS y lo pegas en el navegador:
1.  Tu petición llega al ALB.
2.  El ALB la pasa a uno de los 2 servidores.
3.  El servidor lee el código PHP.
4.  El código conecta a la RDS (MySQL) para login y al EFS para leer tu foto de perfil.
5.  Ves la portada de Moodle.
