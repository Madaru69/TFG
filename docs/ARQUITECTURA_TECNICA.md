# Arquitectura Técnica de Despliegue (AWS)

Esta documentación refleja la infraestructura exacta desplegada por el código Terraform.

## Diagrama de Red (Network Topology)

El siguiente diagrama detalla la segmentación de red, zonas de disponibilidad y grupos de seguridad aplicados.

```mermaid
graph TD
    subgraph AWS_Cloud [AWS Cloud (eu-south-2)]
        
        internet((Internet)) --> IGW[Internet Gateway]
        IGW --> ALB_SG

        subgraph VPC [VPC: 10.0.0.0/16]
            
            subgraph Public_Zone [Capa Pública]
                
                subgraph AZ_A_Pub [AZ A (eu-south-2a)]
                    ALB_Node_A[ALB Node A]
                    EC2_A[EC2 Moodle A]
                end
                
                subgraph AZ_B_Pub [AZ B (eu-south-2b)]
                    ALB_Node_B[ALB Node B]
                    EC2_B[EC2 Moodle B]
                end
                
            end
            
            subgraph Private_Zone [Capa Privada (Datos)]
                
                subgraph AZ_A_Priv [AZ A (eu-south-2a)]
                    RDS_Master[(RDS MySQL Master)]
                    EFS_Mount_A[EFS Mount Target A]
                end
                
                subgraph AZ_B_Priv [AZ B (eu-south-2b)]
                    RDS_Standby[(RDS Standby/Replica)]
                    EFS_Mount_B[EFS Mount Target B]
                end
                
            end

        end
    end

    %% Flujos de Tráfico
    ALB_SG -->|Port 80| ALB_Node_A
    ALB_SG -->|Port 80| ALB_Node_B
    
    ALB_Node_A -->|Target Group| EC2_A
    ALB_Node_B -->|Target Group| EC2_B

    %% Security Groups Logic
    classDef sg fill:#e1f5fe,stroke:#01579b,stroke-width:2px;
    
    ALB_SG[SG: alb-sg <br/> Ingress: 0.0.0.0/0:80]:::sg
    EC2_SG[SG: web-sg <br/> Ingress: alb-sg:80]:::sg
    DATA_SG[SG: rds-sg / efs-sg <br/> Ingress: web-sg:3306/2049]:::sg

    EC2_A -.->|Security Group Allow| EC2_SG
    EC2_B -.->|Security Group Allow| EC2_SG

    EC2_A -->|SQL: 3306| RDS_Master
    EC2_B -->|SQL: 3306| RDS_Master
    
    EC2_A -->|NFS: 2049| EFS_Mount_A
    EC2_B -->|NFS: 2049| EFS_Mount_B

    RDS_Master -.->|Security Group Allow| DATA_SG
    EFS_Mount_A -.->|Security Group Allow| DATA_SG

```

## Detalles Técnicos

### 1. Segmentación de Red
*   **VPC CIDR:** `10.0.0.0/16`
*   **Subnets Públicas:** Alojan el Balanceador de Carga (ALB) y, en esta fase del TFG, las instancias EC2 para facilitar la salida a internet sin costes de NAT Gateway.
*   **Subnets Privadas:** Alojan exclusivamente la persistencia (RDS y EFS) por seguridad.

### 2. Grupos de Seguridad (Firewall Virtual)
La seguridad se aplica en capas ("Defense in Depth"):
1.  **Nivel 1 (Borde):** `alb-sg` permite tráfico HTTP (80) de todo el mundo.
2.  **Nivel 2 (Aplicación):** `web-sg` **DENIEGA** todo el tráfico excepto el que venga del `alb-sg`. Nadie puede atacar la IP de la EC2 directamente por el puerto 80 si no pasa por el balanceador.
3.  **Nivel 3 (Datos):** `rds-sg` y `efs-sg` **DENIEGAN** todo excepto lo que venga de `web-sg`. La base de datos es invisible para internet e incluso para el balanceador.

### 3. Alta Disponibilidad (HA)
El sistema es resistente a la caída de un Centro de Datos completo (AZ).
*   Si cae `eu-south-2a`, el ASG levanta nodos en `eu-south-2b`.
*   La RDS tiene capacidad Multi-AZ (preparada en arquitectura) y el EFS es regional por defecto.
