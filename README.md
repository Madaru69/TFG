# Bytemind-IaC: Moodle High Availability on AWS 🚀🛡️

<img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform">
<img src="https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS">
<img src="https://img.shields.io/badge/Moodle-F98012?style=for-the-badge&logo=moodle&logoColor=white" alt="Moodle">
<img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL">

**Proyecto Fin de Grado (TFG)** centrado en la evolución de infraestructuras: transformando un despliegue **Moodle Monolítico** tradicional en una arquitectura **descentralizada, resiliente y escalable** en la nube de AWS mediante Infrastructure as Code (IaC).

---

## 🏛️ Evolución de la Ingeniería: Del Monolito a la Alta Disponibilidad
El valor diferencial de este TFG es la transición técnica desde un modelo frágil hacia uno de alta resiliencia.

### 🔴 Antes: Arquitectura Monolítica (Standard Moodle)
*Infraestructura básica con punto único de fallo. Todos los servicios conviven en el mismo servidor (EC2).*

<img src="docs/diagrams/moodle_monolith_traditional.png" alt="Arquitectura Monolítica Tradicional" width="800">

### 🟢 Después: Arquitectura Bytemind HA (Bytemind-IaC Design)
*Propuesta de grado empresarial con capas desacopladas y redundancia total.*

<img src="docs/diagrams/moodle_ha_professional.png" alt="Arquitectura Bytemind HA" width="800">

---

## 🏗️ Showcase: Arquitectura de Ingeniería Validada
*Diagrama técnico final detallado, validado mediante Chaos Engineering y pruebas de carga.*

<img src="docs/diagrams/moodle_ha_final_architecture.png" alt="Arquitectura Ingeniería Detallada" width="800">

---

## 🛠️ Retos Técnicos y Soluciones
Para este TFG, se resolvieron problemas reales de nivel empresarial:

| Reto Técnico | Solución Implementada | Habilidad Demostrada |
| :--- | :--- | :--- |
| **Alta Disponibilidad** | Despliegue Multi-AZ con Auto Scaling y ALB. | Arquitectura en la Nube |
| **Persistencia** | Desacoplamiento de datos con RDS y archivos con EFS. | Gestión de Datos |
| **Resiliencia** | Simulación de fallos (Chaos Engineering) con recuperación automática. | SRE / DevOps |
| **FinOps** | Infraestructura efímera mediante despliegues dinámicos y destrucción de recursos. | Optimización de Costes |
| **Automatización** | Configuración dinámica de Moodle (PHP) vía User Data y variables de Terraform. | Automatización IaC |

---

## 📂 Estructura del Proyecto
*   **[`/`](./):** Código Terraform **Golden-Stable (V18)**.
*   **[`docs/`](./docs/):** Memoria técnica, diagramas Mermaid y [galería de alta fidelidad](./docs/architecture_visuals.md).
*   **[`archive/`](./archive/):** Trazabilidad completa del desarrollo (Backups e histórico).

## 🚀 Despliegue Rápido
```bash
terraform init
terraform apply
```

---
**David Arbelaez Mutis - TFG Bytemind-IaC (2026)**
*"Automatizando la educación, asegurando el mañana."*

<img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn">
