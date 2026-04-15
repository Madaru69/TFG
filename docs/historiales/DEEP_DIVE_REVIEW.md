# Auditoría Profunda ("Deep Dive") del Proyecto

He vuelto a revisar el código línea por línea ("con lupa") y he encontrado detalles más sutiles que demostrarán al tribunal que dominas el proyecto a un nivel **Senior**.

Aquí tienes 4 puntos clave que suelen pasar desapercibidos pero son vitales en el mundo real.

---

## 1. El mito de la "Alta Disponibilidad" (HA) y la Base de Datos
En tu memoria afirmas tener una arquitectura de Alta Disponibilidad.
*   **Computación (EC2/ASG):** ✅ ES HA. Si cae la Zona A, el ASG levanta servidores en la Zona B.
*   **Archivos (EFS):** ✅ ES HA. EFS es un servicio regional por diseño.
*   **Base de Datos (RDS):** ⚠️ **NO ES HA** tal como está configurada.

En `storage.tf`:
```hcl
multi_az = false
```
Si AWS sufre un apagón en la Zona de Disponibilidad donde vive tu MoodleDB (ej: `eu-south-2a`), **tu plataforma educativa dejará de funcionar**, aunque tengas servidores web vivos en la Zona B.

**Argumento para la Defensa:**
"Soy consciente de que la Base de Datos es un Punto Único de Fallo (SPOF) en esta configuración concreta. Terraform permite activar `multi_az = true` cambiando una sola línea, lo que replicaría la BD en la otra zona de forma síncrona. Sin embargo, **por restricciones presupuestarias del TFG** (Multi-AZ duplica el coste de RDS), he optado por la versión 'Standby', priorizando la demostración de la lógica de Auto Scaling en la capa web."

---

## 2. El Riesgo de Rendimiento en el Arranque (El problema del `chown`)
En tu `user_data` (`asg.tf`), ejecutas esto en cada arranque:
```bash
mount ... /var/www/html/moodle/moodledata
chown -R www-data:www-data /var/www/html/moodle
```
**El problema:** `chown -R` es recursivo. Si tu plataforma Moodle crece y el directorio `moodledata` (que está en red, EFS) llega a tener 100.000 archivos de alumnos (PDFs, trabajos), este comando intentará cambiar los permisos archivo por archivo a través de la red.
Esto puede hacer que **el servidor tarde 15 o 20 minutos en arrancar** ("Boot Storm"), superando el tiempo de espera del Health Check y causando que el ASG termine la instancia creyendo que está rota.

**Solución "Pro":**
Cambiar los permisos solo si es necesario o solo al directorio raíz del montaje, asumiendo que el contenido dentro ya tiene los permisos correctos (ya que EFS los preserva).
```bash
# Mejor: Cambiar solo la carpeta raíz, no el contenido recursivo
chown www-data:www-data /var/www/html/moodle/moodledata
```

---

## 3. Seguridad: Gestión del Estado de Terraform
No tienes configurado un `backend` en `provider.tf`. Esto significa que el archivo `terraform.tfstate` (donde Terraform guarda lo que ha creado) se guarda en tu carpeta local.
*   **Riesgo:** Si pierdes tu portátil o borras la carpeta, Terraform "olvida" qué infraestructura ha creado y no podrás destruirla ni actualizarla (tendrás que borrar todo manualmente en la consola AWS).
*   **Mejora Teórica:** En un entorno profesional, usaríamos un **Bucket S3** con bloqueo mediante **DynamoDB** para guardar este estado de forma remota y segura.

---

## 4. Observabilidad (Logs)
Tus instancias nacen y mueren automáticamente.
**¿Qué pasa si una instancia falla al arrancar?** Como la instancia se borra, sus logs (`/var/log/syslog` o `/var/log/user-data.log`) desaparecen con ella. No tendrás forma de saber por qué falló.
**Recomendación:** Mencionar en "Líneas Futuras" la instalación del **Agente de CloudWatch** para enviar los logs a un repositorio centralizado antes de que el servidor se autodestruya.

---

## Resumen para tu Nota Final
Si el tribunal te pregunta "¿Qué mejorarías si tuvieras presupuesto ilimitado?", esta es tu carta ganadora:
1.  Activar **RDS Multi-AZ**.
2.  Pasar el estado de Terraform a **S3 Backends**.
3.  Centralizar logs con **CloudWatch**.
4.  Optimizar el script de arranque para evitar cuellos de botella en EFS.
