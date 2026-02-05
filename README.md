# Bytemind-IaC: Despliegue de Moodle en AWS con Alta Disponibilidad 🚀🛡️

Proyecto Fin de Grado (TFG) centrado en la automatización de infraestructura como código (IaC) para un entorno educativo resiliente y escalable.

## 📁 Estructura del Repositorio
Para garantizar la máxima claridad académica y técnica, el repositorio se ha organizado de la siguiente manera:

*   **Raíz (`/`):** Contiene el código Terraform **final y validado (V18)**. Esta versión incluye el parche de desbloqueo de IP y la configuración de Alta Disponibilidad.
*   **`docs/`:** Documentación técnica y visual.
    *   `architecture_diagram.md`: Esquema detallado de la red y sistemas.
    *   `architecture_visuals.md`: Galería de imágenes en alta fidelidad.
    *   `diagrams/`: Archivos de imagen originales.
*   **`archive/`:** Historial de versiones previas, backups y estados de terraform antiguos para trazabilidad del desarrollo.

## 🏛️ Arquitectura Destacada (High Availability)
El sistema está diseñado para sobrevivir a fallos de centros de datos mediante:
- **Multi-AZ Deployment:** Instancias repartidas en `eu-south-2a` y `eu-south-2b`.
- **Auto-Healing:** Recuperación automática de nodos mediante AWS Auto Scaling.
- **Persistencia Desacoplada:** Amazon RDS para bases de datos y Amazon EFS para archivos.

## 🚀 Cómo Desplegar
1.  Asegúrate de tener configuradas tus credenciales de AWS.
2.  `terraform init`
3.  `terraform apply`

---
**David - TFG Bytemind-IaC (2026)**
"Automatizando el aprendizaje, securizando el futuro."
