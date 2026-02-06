# 🧪 Guía de Validación de Arquitectura: Chaos & Stress Testing

Esta guía detalla cómo poner a prueba la infraestructura **Bytemind-IaC** para demostrar que el Auto Scaling y la Alta Disponibilidad funcionan exactamente como se diseñaron.

> [!IMPORTANT]
> Para realizar estas pruebas, la infraestructura debe estar desplegada (`terraform apply`).

---

## 1. Prueba de Caos (Auto-Healing) 🛡️
**Objetivo:** Demostrar que si un servidor "muere", el sistema lo reemplaza automáticamente sin pérdida de servicio.

### Pasos:
1.  Accede a la consola de AWS -> **EC2 Instances**.
2.  Selecciona una de las dos instancias activas de Moodle.
3.  Dale a **Terminate Instance** (Simulando un fallo crítico de hardware).
4.  **Observación:**
    *   El **Load Balancer (ALB)** detectará el fallo y dejará de enviarle tráfico (en ~30-60 seg).
    *   Moodle seguirá funcionando porque la otra instancia está operativa.
    *   El **Auto Scaling Group (ASG)** notará que solo hay 1 instancia (cuando el mínimo es 2) y lanzará una nueva automáticamente.
    *   En unos 3-5 minutos, volverás a tener 2 instancias saludables.

---

## 2. Prueba de Carga (Auto-Scaling) 📈
**Objetivo:** Demostrar que el sistema crece horizontalmente ante un pico de tráfico real.

### Pasos:
1.  Entra por SSH a una de tus instancias (vía SSM o terminal).
2.  Instala la herramienta `stress`:
    ```bash
    sudo apt update && sudo apt install stress -y
    ```
3.  Lanza el ataque de estrés al CPU (esto simulará miles de usuarios entrando a la vez):
    ```bash
    # Estresa 4 núcleos durante 10 minutos
    stress --cpu 4 --timeout 600
    ```
4.  **Observación:**
    *   Ve a la consola de AWS -> **Auto Scaling Groups** -> **Monitoring**.
    *   Cuando el uso medio de CPU del grupo supere el umbral configurado (ej: 70%), el ASG lanzará una 3ª y hasta una 4ª instancia.
    *   Verás cómo se activan nuevas máquinas para repartir la carga.

---

## 3. Verificación de Capa de Datos (Persistencia) 💾
**Objetivo:** Confirmar que los datos no se pierden al morir los servidores.

### Pasos:
1.  Sube un archivo o crea un curso en Moodle.
2.  Borra **ambas** instancias EC2 a la vez.
3.  Espera a que el ASG las reponga.
4.  Entra a Moodle.
5.  **Resultado esperado:** El curso y los archivos siguen ahí. Esto demuestra que el almacenamiento está correctamente desacoplado en **RDS** y **EFS**.

---

## 4. Validación Nativa con Terraform 🛠️
Terraform permite validar la capacidad de gestión del estado y la resiliencia de la configuración sin salir de la terminal.

### A. Prueba de Escalado Manual
Cambia la configuración para ver cómo Terraform ajusta la infraestructura en caliente.
1.  En `asg.tf`, cambia `desired_capacity = 2` a `desired_capacity = 3`.
2.  Ejecuta `terraform apply`.
3.  **Resultado:** Terraform detectará la diferencia y lanzará una nueva instancia inmediatamente para cumplir con el estado deseado.

### B. Simulación de Corrupción (Reemplazo Forzado)
Si sospechas que una instancia está mal configurada, puedes forzar su reemplazo.
1.  Lista tus instancias: `terraform state list | grep aws_instance` (Si usaras instancias fijas).
2.  Como usamos un ASG, podemos forzar el reemplazo de la **Plantilla de Lanzamiento**:
    ```bash
    terraform apply -replace="aws_launch_template.moodle_lt"
    ```
3.  **Resultado:** Terraform destruirá y recreará la plantilla, y el ASG realizará un **Rolling Update** (renovará las máquinas una a una) sin que Moodle deje de funcionar.

---

## 5. Prueba de Tráfico Escalar (Network Load) 🌐
**Objetivo:** Demostrar que el sistema crece por número de peticiones, incluso si el CPU no sufre.

### Pasos:
1.  Instala una herramienta de benchmark (ej: `ab` de Apache) en tu ordenador local o en una instancia auxiliar.
2.  Lanza un ataque de peticiones controladas al Load Balancer:
    ```bash
    # Lanza 10,000 peticiones, de 10 en 10
    ab -n 10000 -c 10 http://<tu-url-moodle>/
    ```
3.  **Observación:**
    *   Ve a **CloudWatch Alarms**. Verás que la alarma `TargetTracking-moodle-request-policy` se activa al superar las 100 peticiones/min.
    *   El ASG lanzará una nueva instancia para repartir la "carga de red".

---
**David Arbelaez Mutis - TFG 2026**
*"Diseñado para fallar, construido para sobrevivir."*
