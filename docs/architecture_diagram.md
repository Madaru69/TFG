# Arquitectura de Sistemas: Moodle High Availability (Bytemind-IaC)

Esta arquitectura representa el diseño consolidado tras la Fase de Recuperación V18 y la Validación de Alta Disponibilidad.

```mermaid
flowchart TB
    %% --- ACTORES ---
    User((Estudiante/Admin))
    
    subgraph cloud ["AWS Cloud (eu-south-2)"]
        subgraph vpc ["VPC (10.0.0.0/16)"]
            direction TB
            IGW["Internet Gateway"]
            
            subgraph public ["Public Tier (Multi-AZ)"]
                ALB["Application Load Balancer"]
                EC2A["EC2 Node A (t3.medium)"]
                EC2B["EC2 Node B (t3.medium)"]
            end

            subgraph engine ["Scaling Engine"]
                ASGBrain{"ASG Policy<br/>(CPU + Traffic)"}
            end

            subgraph private ["Private Tier (Data)"]
                RDS[("Amazon RDS (DB)")]
                EFS["Amazon EFS (Files)"]
            end
        end
    end

    %% --- FLUJO ---
    User --> IGW --> ALB
    ALB --> EC2A
    ALB --> EC2B
    
    %% --- ESCALADO ---
    EC2A -.-> ASGBrain
    EC2B -.-> ASGBrain
    ALB -.-> ASGBrain
    ASGBrain == Launch ==> EC2A
    ASGBrain == Launch ==> EC2B

    %% --- DATOS ---
    EC2A --- RDS
    EC2B --- RDS
    EC2A --- EFS
    EC2B --- EFS

    %% --- ESTILOS ---
    style IGW fill:#e1f5fe,stroke:#01579b
    style ALB fill:#e1f5fe,stroke:#01579b
    style EC2A fill:#ede7f6,stroke:#4527a0
    style EC2B fill:#ede7f6,stroke:#4527a0
    style ASGBrain fill:#fff9c4,stroke:#fbc02d
    style RDS fill:#e8f5e9,stroke:#1b5e20
    style EFS fill:#e8f5e9,stroke:#1b5e20
    style cloud fill:#f9f9f9,stroke:#333,stroke-dasharray: 5 5
```

---

## 🚀 Evolución: Del Monolito a la Descentralización

Un punto clave del TFG es la transición desde un despliegue tradicional hacia uno de grado empresarial.

### 🔴 Antes: Arquitectura Monolítica (Standard Moodle)
En un despliegue básico, todos los componentes conviven en un único servidor:
- **Punto Único de Fallo:** Si la instancia EC2 falla, todo el sistema cae.
- **Escalabilidad Nula:** Para crecer, hay que aumentar el tamaño de la máquina (Escalado Vertical), lo cual es costoso y requiere tiempo de inactividad.
- **Riesgo de Datos:** La base de datos y los archivos están dentro del servidor; si el disco se corrompe, los datos se pierden.

### 🟢 Después: Arquitectura Bytemind HA (Descentralizada)
Nuestra solución desacopla las responsabilidades para maximizar la resiliencia:
- **Cómputo Inmutable:** Las instancias EC2 son efímeras. Si una muere, el ASG lanza otra idéntica automáticamente.
- **Persistencia Externa:** Los datos viven en servicios gestionados (**RDS** y **EFS**) inmunes a fallos de los servidores de aplicaciones.
- **Alta Disponibilidad:** Tráfico distribuido por el **ALB** entre múltiples centros de datos (AZ).

## 🛠️ Especificaciones de la Infraestructura
| Componente | Capa | Resiliencia | Notas de TFG |
| :--- | :--- | :--- | :--- |
| **ALB** | Networking | Distribuido | Punto único de terminación SSL (Fase 4). |
| **ASG** | Cómputo | Auto-Healing | Recuperó la flota automáticamente en el Chaos Test. |
| **RDS** | Datos | Gestionado | Backups automatizados y aislamiento en subred privada. |
| **EFS** | Almacenamiento | Multi-AZ | Punto de montaje común para sesiones y archivos. |

## 🛡️ Hitos de Ingeniería Digital (V18)
1.  **Aislamiento de Seguridad:** Ninguna instancia EC2 tiene IP pública directa; todo el tráfico pasa por el ALB.
2.  **Despliegue Inmutable:** El `config.php` se autoconfigura en el arranque para evitar errores de conexión.
3.  **FinOps Strategy:** El entorno está diseñado para ser **efímero**. Se despliega para exámenes/clases y se destruye (`Destroy`) al finalizar, ahorrando el 100% del coste residual.
