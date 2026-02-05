# Bytemind-IaC: Moodle High Availability on AWS 🚀🛡️

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Moodle](https://img.shields.io/badge/Moodle-F98012?style=for-the-badge&logo=moodle&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)

**Proyecto Fin de Grado (TFG)** centrado en la evolución de infraestructuras: transformando un despliegue **Moodle Monolítico** tradicional en una arquitectura **descentralizada, resiliente y escalable** en la nube de AWS mediante Infrastructure as Code (IaC).

---

## 🏛️ Evolución de la Ingeniería: Monolito vs Alta Disponibilidad
El valor principal de este proyecto es el salto tecnológico desde un servidor único ("Todo en uno") hacia una arquitectura de grado empresarial:

- **Infraestructura Monolítica:** Un punto único de fallo, escalado vertical costoso y riesgo de pérdida de datos.
- **Bytemind HA (Descentralizada):** Cómputo inmutable, capas de persistencia externas (RDS/EFS) y auto-curación distribuida en múltiples zonas de disponibilidad.

![Arquitectura de Sistemas](docs/diagrams/moodle_ha_final_architecture.png)

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
**David - TFG Bytemind-IaC (2026)**
*"Automatizando la educación, asegurando el mañana."*

![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)
