# Protocolo de Validación y Resiliencia (Chaos Engineering)

**Objetivo del Experimento:** Demostrar que la arquitectura propuesta es capaz de sobrevivir a la pérdida crítica de uno de sus nodos de computación sin afectar la disponibilidad del servicio educativo para el usuario final.

Este procedimiento se basa en la metodología de "Inyección controlada de fallos" descrita en la memoria del proyecto.

## Prueba 1: "El Exterminador" (Termination of Instance)

En este escenario, simularemos un fallo catastrófico de hardware terminando abruptamente una de las instancias EC2 que sirven la aplicación Moodle.

### 1. Insumos y Estado Inicial
*   Infraestructura desplegada y estable.
*   **2 Instancias EC2** en estado `InService` bajo el Auto Scaling Group.
*   Acceso a la consola de AWS o CLI.

### 2. Procedimiento (Paso a Paso)

1.  **Identificación de Víctima:**
    Localiza el ID de una de las instancias activas (ej. `i-0123456789abcdef0`).
    
2.  **Inyección del Fallo:**
    Desde la terminal, ejecuta el comando para terminar la instancia (simulación de fallo irreversible):
    ```bash
    aws ec2 terminate-instances --instance-ids <ID_DE_LA_INSTANCIA>
    ```

3.  **Observación del Comportamiento (Monitorización):**
    *   **Inmediato:** El *Application Load Balancer* detectará que el nodo no responde a los *Health Checks*.
    *   **Respuesta del Sistema:** El *Auto Scaling Group* notará que la capacidad actual (1) es inferior a la deseada (2).
    *   **Acción Correctiva:** Se lanzará automáticamente una nueva instancia.

### 3. Resultados Esperados (Validación)

Para considerar la prueba exitosa, se debe lograr evidenciar lo siguiente:

*   [ ] **Continuidad del Servicio:** Al recargar la página de Moodle durante el fallo, el sitio debe seguir respondiendo (servido por la instancia sobreviviente en la otra Zona de Disponibilidad).
*   [ ] **Auto-Recuperación:** En menos de 5 minutos, el ASG debe haber aprovisionado un nuevo nodo y este debe haberse unido al clúster correctamente.
*   [ ] **Persistencia de Datos:** Los archivos subidos antes del fallo deben estar accesibles en la nueva instancia (gracias a EFS).

> [!IMPORTANT]
> Esta prueba valida la hipótesis fundamental del TFG: **La eliminación del Punto Único de Fallo (SPOF).**
