# Infraestructura Cloud de Alta Disponibilidad para Moodle en AWS

**Autor:** David Arbelaez Mutis  
**Proyecto:** TFG - Administración de Sistemas Informáticos en Red (ASIR)

## 1. Contexto y Justificación Social

En el panorama educativo actual, la disponibilidad de las plataformas LMS (*Learning Management Systems*) como Moodle es crítica. No se trata solo de tecnología; una caída del servicio en época de exámenes afecta directamente al progreso académico de los estudiantes y a la equidad en el acceso a la educación.

Este proyecto aborda la modernización de una infraestructura "monolítica" hacia una arquitectura **Cloud Native** en AWS, diseñada para ser resiliente, elástica y eficiente en costes.

## 2. Metodología: Del Monolito a la Nube

Se plantea un enfoque iterativo basado en **Insumos** (Requisitos de Moodle), **Procesamiento** (Codificación en Terraform) y **Salidas** (Infraestructura Desplegada).

### 2.1 Insumos y Tecnologías
*   **Terraform (IaC):** Para garantizar la replicabilidad y eliminar la gestión manual ("ClickOps").
*   **AWS (Región España `eu-south-2`):** Para minimizar latencia y cumplir con soberanía de datos.
*   **FinOps:** Estrategia de etiquetado y selección de recursos (`t3.micro`) para optimizar el presupuesto del laboratorio.

### 2.2 Arquitectura Propuesta (Salida Gráfica)
El diseño implementa una topología de tres capas con **Alta Disponibilidad (HA)**:
1.  **Capa de Presentación:** Application Load Balancer (ALB) público.
2.  **Capa de Computación:** Auto Scaling Group (ASG) distribuido en Zonas A y B.
3.  **Capa de Datos:** Amazon RDS (Base de datos) y Amazon EFS (Archivos) desacoplados.

## 3. Guía de Despliegue

Sigue estos pasos para levantar el entorno en tu cuenta de AWS.

### Requisitos Previos
*   AWS CLI configurado.
*   Terraform instalado.
*   Par de claves SSH (`tfg-key.pem`) en el directorio raíz.

### Procedimiento
1.  **Inicializar Terraform:**
    ```bash
    terraform init
    ```
2.  **Validar Planificación:**
    Se recomienda revisar el plan de ejecución para detectar posibles conflictos.
    ```bash
    terraform plan
    ```
3.  **Despliegue (Apply):**
    ```bash
    terraform apply -auto-approve
    ```

> [!NOTE]
> El tiempo estimado de aprovisionamiento es de 5 a 10 minutos. El *User Data* se encargará de montar el EFS automáticamente.

4.  **Verificación:**
    Obtén la URL del Balanceador de Carga desde las salidas de Terraform y accede desde tu navegador:
    ```bash
    terraform output alb_dns_name
    ```

## 4. Pruebas de Resiliencia ("Chaos Monkey")

Para validar que la arquitectura cumple con su objetivo de soportar fallos sin interrumpir el servicio educativo, consulta la guía de pruebas:
[>> Ir a Guía de Pruebas de Caos (El Exterminador)](./chaos_testing.md)

---
*Este proyecto es un esfuerzo académico para demostrar cómo la ingeniería de sistemas puede resolver problemas reales de accesibilidad y estabilidad en entornos formativos.*
