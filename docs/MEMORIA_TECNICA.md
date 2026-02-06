# MEMORIA TÉCNICA DEL PROYECTO
## DISEÑO E IMPLEMENTACIÓN DE INFRAESTRUCTURA CLOUD NATIVE DE ALTA DISPONIBILIDAD PARA PLATAFORMAS DE E-LEARNING (MOODLE)

**Ciclo Formativo:** Administración de Sistemas Informáticos en Red (ASIR)  
**Autor:** [Tu Nombre]  
**Tutor:** [Nombre del Tutor]  
**Fecha:** Febrero 2026

---

## RESUMEN EJECUTIVO

El presente proyecto aborda la problemática de la escalabilidad y disponibilidad en entornos educativos digitales críticos. Tradicionalmente, las plataformas LMS (*Learning Management Systems*) como Moodle se despliegan en arquitecturas monolíticas "on-premise", lo que resulta en puntos únicos de fallo y falta de elasticidad ante picos de demanda (ej. periodos de exámenes).

Este Trabajo de Fin de Grado (TFG) propone y valida una migración hacia una arquitectura **Cloud Native** en Amazon Web Services (AWS), orquestada mediante **Infraestructura como Código (IaC)** con Terraform. La solución implementa un diseño de tres capas con escalado automático, almacenamiento distribuido y segregación de redes, garantizando la continuidad del servicio y optimizando los costes operativos mediante estrategias FinOps.

---

## 1. INTRODUCCIÓN Y JUSTIFICACIÓN

### 1.1 Antecedentes
En el contexto actual, la teleformación no es una opción, sino una necesidad estructural. Los centros educativos enfrentan el reto de mantener servicios 24/7. Las infraestructuras tradicionales basadas en un único servidor (VPS o físico) presentan riesgos inasumibles:
1.  **SPOF (Single Point of Failure):** Si el servidor falla, el servicio se detiene.
2.  **Rigidez:** Los recursos (CPU/RAM) son estáticos, pagando por capacidad ociosa o colapsando por falta de ella.

### 1.2 Objetivos del Proyecto
El objetivo general es diseñar una infraestructura resiliente que elimine la dependencia de un único nodo físico.

**Objetivos Específicos:**
*   Implementar una arquitectura de **Alta Disponibilidad (HA)** en múltiples Zonas de Disponibilidad (AZ).
*   Desacoplar la capa de computación (EC2) de la capa de datos (RDS/EFS).
*   Automatizar el despliegue mediante Terraform para garantizar la **Idempotencia** y **Recuperación ante Desastres (DR)**.

---

## 2. METODOLOGÍA Y HERRAMIENTAS

Para el desarrollo del proyecto se ha seguido una metodología iterativa incremental, apoyada en las siguientes tecnologías:

*   **Proveedor Cloud:** AWS (Región `eu-south-2` - España), seleccionada por cumplimiento de normativas de latencia y soberanía de datos.
*   **IaC:** Terraform v1.x, permitiendo versionar la infraestructura como si fuera software.
*   **Motor de Base de Datos:** Amazon RDS (MySQL 8.0).
*   **Sistema de Archivos:** Amazon EFS (NFSv4), fundamental para que múltiples servidores web compartan el directorio `moodledata`.

---

## 3. ARQUITECTURA PROPUESTA

Se ha diseñado una topología de red VPC (*Virtual Private Cloud*) segmentada para maximizar la seguridad y el rendimiento.

### 3.1 Diseño de Red (Networking)
La red `10.0.0.0/16` se divide en:
*   **Subredes Públicas (Capa de Presentación):** Alojando exclusivamente el **Application Load Balancer (ALB)**.
*   **Subredes Privadas (Capa de Aplicación y Datos):** Donde residen las instancias EC2 y las bases de datos, sin acceso directo desde internet para reducir la superficie de ataque.

### 3.2 Elasticidad (Auto Scaling)
El componente crítico es el **Auto Scaling Group (ASG)**. A diferencia de un servidor fijo, el ASG monitoriza la salud de las aplicaciones.
*   **Umbral Mínimo:** 2 Instancias (garantizando redundancia en Zona A y Zona B).
*   **Umbral Máximo:** 4 Instancias (permitiendo absorber picos de carga).

### 3.3 Persistencia de Datos
Dado que los servidores son efímeros (pueden ser creados y destruidos automáticamente), el estado se externaliza:
*   **Sesiones y Datos Estructurados:** Amazon RDS.
*   **Archivos (Moodledata):** Amazon EFS. Esto permite que un alumno suba un archivo conectado al Servidor A y pueda descargarlo inmediatamente aunque su siguiente petición sea atendida por el Servidor B.

---

## 4. DESARROLLO E IMPLEMENTACIÓN

La codificación se ha realizado en HCL (*HashiCorp Configuration Language*), estructurando el proyecto en módulos lógicos:

### 4.1 Definición de Recursos
*   **`compute.tf` / `asg.tf`:** Se definen las *Launch Templates* que incluyen el script de inicialización (`user_data`). Este script es vital, pues automatiza el montaje del volumen EFS en `/var/www/html/moodle/moodledata` durante el arranque de cada nuevo nodo.
*   **`security.tf`:** Se aplica el principio de **Mínimo Privilegio**.
    *   El Servidor Web solo acepta tráfico HTTP del Balanceador.
    *   La Base de Datos solo acepta tráfico MySQL del Servidor Web.

### 4.2 Despliegue
El ciclo de vida se gestiona mediante los comandos estándar de Terraform:
1.  `terraform plan`: Previsualización de cambios.
2.  `terraform apply`: Orquestación de llamadas a la API de AWS para crear los 24 recursos definidos.

---

## 5. VALIDACIÓN Y PRUEBAS DE CAOS

Para verificar la robustez del sistema, se ha aplicado metodología de **Ingeniería del Caos** (*Chaos Engineering*).

**Prueba Realizada: Simulación de Fallo de Nodo**
1.  **Escenario:** Se fuerza la terminación manual de una instancia EC2 en la Zona A.
2.  **Comportamiento del Sistema:**
    *   El ALB detecta el fallo en los *Health Checks*.
    *   El tráfico se redirige automáticamente a la instancia superviviente en la Zona B.
    *   El usuario final no percibe interrupción del servicio.
    *   El ASG aprovisiona un nuevo nodo de reemplazo en menos de 180 segundos.

---

## 6. CONCLUSIONES Y LÍNEAS FUTURAS

### 6.1 Conclusiones
El proyecto demuestra que es posible desplegar una arquitectura empresarial compleja utilizando código. Se cumple el objetivo de eliminar el punto único de fallo en la capa de cómputo y almacenamiento, logrando un sistema tolerante a fallos.

### 6.2 Limitaciones y Mejoras (Trabajo Futuro)
Se identifican áreas de mejora para una futura iteración en un entorno de producción real:
1.  **Redundancia de Base de Datos:** Actualmente, RDS se despliega en modo *Single-AZ* por restricciones presupuestarias del entorno académico. En producción, se activaría el parámetro `multi_az = true` para replicación síncrona.
2.  **Cifrado en Tránsito:** Implementación de certificados SSL/TLS mediante AWS ACM en el balanceador de carga.
3.  **Observabilidad:** Integración de *CloudWatch Logs Agent* para centralizar los registros de las instancias antes de su terminación por escalado.

---
**Referencias:**
*   Documentación Oficial de AWS (Well-Architected Framework).
*   Documentación de Terraform (Registry).
*   Moodle Clustering Documentation.
