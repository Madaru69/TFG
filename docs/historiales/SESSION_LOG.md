# Log de Trabajo - Revisión TFG
**Fecha:** 06 de Febrero de 2026
**Estado:** Listo para subir a GitHub

## 1. Resumen de Actividades
Se ha completado la revisión y optimización del repositorio `Madaru69/TFG` utilizando los archivos locales como referencia.

### Cambios Realizados en el Código
*   **Optimización de Arranque (`asg.tf`)**: Se modificó el script `user_data` para evitar un cambio de permisos recursivo (`chown -R`) en todo el sistema de archivos EFS. Esto previene tiempos de arranque excesivos ("Boot Storms") cuando la plataforma escala.
*   **Etiquetado FinOps (`provider.tf`)**: Se añadieron `default_tags` para identificar automáticamente todos los recursos (Proyecto, Propietario, Entorno).

### Sincronización de Documentación
*   **README.md**: Actualizado con la versión detallada y profesional.
*   **Memoria Técnica**: Se copió `MEMORIA_TFG_PROFESIONAL.md` a la carpeta `docs/MEMORIA_TECNICA.md` para que la documentación completa viva junto al código.
*   **Chaos Testing**: Se aseguró la presencia de `chaos_testing.md`.

## 2. Herramientas del Entorno
Se ha preparado este equipo para trabajar con la infraestructura:
*   **Terraform**: Instalado manualmente en `C:\Users\Alumno.DESKTOP-DI5KTUG\bin\terraform.exe` (v1.5.7).
*   **AWS CLI**: Instalado vía Winget.

## 3. Verificación
Se ejecutó `terraform validate` con resultado exitoso:
> "Success! The configuration is valid."

## 4. Próximos Pasos (Para retomar)
1.  Abrir terminal en `TFG_Review/TFG`.
2.  Configurar credenciales de AWS (`aws configure`).
3.  Hacer commit y push de los cambios:
    ```bash
    git add .
    git commit -m "feat: optimizacion boot time y docs actualizados"
    git push
    ```
