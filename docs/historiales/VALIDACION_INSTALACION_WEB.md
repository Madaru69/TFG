# ¿Por qué falla la instalación Web en un Auto Scaling Group?

Has planteado una duda muy importante: *"¿Puedo iniciar sesión por web y configurar la base de datos manualmente?"*

La respuesta corta es: **Sí, puedes hacerlo, pero romperá tu infraestructura en cuanto el balanceador te cambie de servidor.**

Aquí te explico por qué ocurre esto y cómo solucionarlo para defender tu TFG.

---

## 1. El Problema de la "Memoria Local"

Cuando instalas Moodle vía web, el asistente genera un archivo llamado `config.php` con la dirección de la base de datos, el usuario y la contraseña.

Este archivo se guarda **localmente** en el disco duro del servidor donde estabas conectado en ese momento.

### Escenario de Fallo (paso a paso):
1.  **Despliegue:** Terraform lanza 2 servidores (`Server A` y `Server B`) y un Balanceador (`ALB`).
2.  **Petición 1:** Entras a la web. El ALB te envía al `Server A`.
3.  **Instalación:** Rellenas los datos de la BD. El `Server A` crea el archivo `config.php` en su disco. Moodle funciona bien... **mientras sigas en el Server A**.
4.  **Petición 2:** Refrescas la página. El ALB decide enviarte al `Server B` para equilibrar la carga.
5.  **Error:** El `Server B` es nuevo. **No tiene el archivo `config.php`** que creaste en el Server A.
    *   Moodle piensa que no está instalado.
    *   Te redirige a la pantalla de instalación `/install.php`.
    *   Intentas instalar de nuevo, pero te dice "La base de datos ya existe".

Esto se conoce como **Inconsistencia de Estado**. En una arquitectura Cloud Native (como la de tu TFG), los servidores son "efímeros" y no guardan estado.

---

## 2. Soluciones Posibles

### Opción A: La solución "Cloud Native" (Recomendada en el informe anterior)
Automatizar la creación del `config.php` usando el **User Data**. Así, cada vez que nace un servidor (sea el primero o el quinto), él mismo se "auto-configura" conectándose a la base de datos correcta.

### Opción B: La solución de "Persistencia Compartida" (Más sencilla)
Si prefieres usar el instalador web, debes hacer que el archivo `config.php` se guarde en el **EFS** (tu disco compartido), no en el servidor local.

**Pasos para implementar esto:**
1.  Modifica tu AMI o tu `user_data` para que Moodle busque la configuración en EFS.
2.  Puedes crear un enlace simbólico (acceso directo):
    ```bash
    # En el user_data de asg.tf
    # Borramos el config local si existe
    rm -f /var/www/html/moodle/config.php
    
    # Creamos un enlace directo al archivo que vivirá en EFS
    ln -s /var/www/html/moodle/moodledata/config.php /var/www/html/moodle/config.php
    ```
3.  Ahora, cuando instales vía web desde el `Server A`, el archivo se escribirá realmente en la carpeta `moodledata` (que está en EFS).
4.  Cuando el `Server B` arranque, verá el mismo archivo a través del enlace simbólico.

---

## 3. Conclusión para tu Defensa
Si el tribunal te pregunta: *"¿Cómo gestionas la configuración en instancias dinámicas?"*
*   **Respuesta incorrecta:** "Lo configuro a mano al entrar".
*   **Respuesta correcta:** "Utilizo automatización para inyectar la configuración en el arranque (User Data) o centralizo el archivo de configuración en un almacenamiento compartido (EFS) para evitar inconsistencias entre nodos."
