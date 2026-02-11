# Bytemind-IaC: Moodle High Availability on AWS 🚀🛡️

<img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"> <img src="https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS"> <img src="https://img.shields.io/badge/Moodle-F98012?style=for-the-badge&logo=moodle&logoColor=white" alt="Moodle"> <img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL">

**Proyecto Fin de Grado (TFG)** enfocado en la excelencia operativa: transformando un despliegue **Moodle Monolítico** convencional en una arquitectura **descentralizada, resiliente y escalable** en la nube de AWS mediante Infrastructure as Code (IaC).

---

## 🏛️ Evolución de la Ingeniería: Del Monolito a la Alta Disponibilidad
Este proyecto documenta el salto tecnológico necesario para mover aplicaciones académicas a entornos de producción de grado empresarial.

### 🔴 Antes: Arquitectura Monolítica (Standard Moodle)
*Infraestructura básica con punto único de fallo. Todos los servicios (Web, DB, Files) conviven en una única instancia EC2.*

<img src="docs/diagrams/moodle_monolith_traditional.png" alt="Arquitectura Monolítica Tradicional" width="800">

### 🟢 Después: Arquitectura Bytemind HA (Bytemind-IaC Design)
*Propuesta de grado empresarial con capas desacopladas, persistencia externa y redundancia Multi-AZ.*

<img src="docs/diagrams/moodle_ha_professional.png" alt="Arquitectura Bytemind HA" width="800">

---

## 🏗️ Showcase: Arquitectura de Ingeniería Validada
*Diagrama técnico final detallado, validado mediante Chaos Engineering y pruebas de carga intensivas.*

<img src="docs/diagrams/moodle_ha_final_architecture.png" alt="Arquitectura Ingeniería Detallada" width="800">

---

## 🛠️ Retos Técnicos y Soluciones de Ingeniería
El proyecto resuelve desafíos críticos del Well-Architected Framework:

| Categoría | Desafío Técnico | Solución Implementada |
| :--- | :--- | :--- |
| **Disponibilidad** | Eliminar puntos de fallo únicos (SPOF). | Despliegue Multi-AZ con Auto Scaling y Balanceador (ALB). |
| **Persistencia** | Sincronización de contenidos entre nodos. | Desacoplamiento de datos con RDS MySQL y archivos con EFS. |
| **Resiliencia** | Recuperación ante fallos críticos. | Automatización SRE: Self-Healing validado con Chaos Testing. |
| **FinOps** | Optimización de costes en infraestructura. | Arquitectura efímera: Despliegue bajo demanda y destrucción total. |
| **Automatización** | Despliegue "Zero-Touch" en AWS. | Configuración dinámica de Moodle vía Terraform y User-Data. |

---

## 📂 Estructura del Proyecto
*   **[`/`](./):** Código Terraform **Golden-Stable (V18)**.
*   **[`docs/`](./docs/):** Memoria técnica, diagramas Mermaid y [galería de alta fidelidad](./docs/architecture_visuals.md).
*   **[`archive/`](./archive/):** Histórico de desarrollo y versiones heredadas.

## 🚀 Despliegue y Acceso
```bash
terraform init
terraform apply
```
Una vez desplegado, el sistema genera automáticamente un **Moodle URL** (vía Outputs) accesible de forma inmediata.

---
**David Arbelaez Mutis - TFG Bytemind-IaC (2026)**
*"Automatizando la educación, asegurando el mañana."*

<a href="https://www.linkedin.com/in/davidmutis/" target="_blank">
  <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn">
</a>
