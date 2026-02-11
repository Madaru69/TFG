# Curso: Introducción al Cloud Computing (AWS Edition)

## Descripción General
Curso técnico para entender qué es la nube, basándonos en los estándares del NIST y la práctica en Amazon Web Services (AWS).

---

## Módulo 1: ¿Qué es la Nube?

### Definición (NIST)
La computación en la nube es un modelo que permite el acceso a **recursos informáticos compartidos** (redes, servidores, almacenamiento, aplicaciones) de manera **ubicua, conveniente y bajo demanda**, con un mínimo esfuerzo de gestión.

### Las 5 Características Esenciales:
1.  **Autoservicio Bajo Demanda:** Tienes lo que quieres, cuando quieres, sin llamar a nadie (como hiciste con `terraform apply`).
2.  **Acceso Amplio a la Red:** Accesible desde móvil, tablet, portátil...
3.  **Pooling de Recursos:** Los servidores físicos de AWS son compartidos por miles de clientes (Multi-tenant).
4.  **Elasticidad Rápida:** Puedes tener 1 servidor hoy y 1000 mañana si tu web se hace viral (Auto Scaling).
5.  **Servicio Medido (Pay-as-you-go):** Pagas solo por lo que usas. Como la luz o el agua.

---

## Módulo 2: Modelos de Servicio (La Pizza as a Service)

Para entender esto, imaginemos hacer una pizza:

1.  **On-Premises (Tu casa):** Tú compras la masa, el tomate, el horno, el gas y la cocinas. Tú eres responsable de TODO.
2.  **IaaS (Infraestructura como Servicio):** Te alquilan la cocina y el horno. Tú traes la pizza y la cocinas.
    *   *Ejemplo:* **AWS EC2**. Amazon te da la máquina virtual, tú instalas el SO y Moodle.
3.  **PaaS (Plataforma como Servicio):** Te traen la pizza hecha, tú pones la mesa y los refrescos.
    *   *Ejemplo:* **AWS RDS**. Amazon gestiona la base de datos, tú solo guardas datos.
4.  **SaaS (Software como Servicio):** Vas a una pizzería. Te sientas y comes. No haces nada.
    *   *Ejemplo:* **Gmail, Dropbox, Spotify**.

---

## Módulo 3: La Práctica - Tu Arquitectura AWS

### Componentes que ya usas:
*   **EC2 (Elastic Compute Cloud):** Son tus servidores virtuales donde corre Moodle.
*   **VPC (Virtual Private Cloud):** Tu trozo privado de red dentro de AWS. Nadie puede entrar si tú no quieres.
*   **ALB (Application Load Balancer):** El policía de tráfico. Recibe las visitas de los alumnos y las reparte entre tus servidores EC2.
*   **ASG (Auto Scaling Group):** El supervisor. Si un servidor muere, el ASG crea otro nuevo inmediatamente.
*   **EFS (Elastic File System):** Una carpeta compartida mágica que todos los servidores ven a la vez.

### Actividad Sugerida
*   **"El Chaos Monkey":** Entrar a la consola de AWS, detener una instancia EC2 manualmente y cronometrar cuánto tarda el sistema en crear una nueva automáticamente.
