# Guía de Despliegue Rápido (AWS + Terraform)

Sigue estos pasos en orden para validar tu TFG en la nube real.

## 1. Configuración de Credenciales (Ya realizado)
Si necesitas re-configurar tu cuenta, ejecuta:
```bash
aws configure
# Access Key: (Tu clave AKIA...)
# Secret Key: (Tu clave secreta...)
# Region: eu-south-2
# Output: json
```
*Comprobación:* `aws sts get-caller-identity` (Debe mostrar tu usuario).

## 2. Inicialización
Descarga los "plugins" necesarios de AWS para Terraform.
```bash
terraform init
```
*Esperar:* mensaje verde "Terraform has been successfully initialized!"

## 3. Planificación (Simulacro)
Revisa qué se va a crear sin gastar dinero todavía.
```bash
terraform plan
```
*Salida:* Verás una lista larga con `+ create`. Al final debe decir algo como `Plan: 28 to add, 0 to change, 0 to destroy`.

## 4. Despliegue (Acción Real)
Crea la infraestructura en AWS. ¡Aquí empieza a facturar (céntimos)!
```bash
terraform apply -auto-approve
```
*Tiempo estimado:* 5-10 minutos (RDS tarda un poco).
*Al finalizar:* Verás los `Outputs` en verde (URL de Moodle, Endpoint DB, etc.).

## 5. Verificación
1. Copia la `moodle_url` que sale al final (ej: `http://tfg-bytemind-lb-....eu-south-2.elb.amazonaws.com`).
2. Abrela en tu navegador.
3. Deberías ver el instalador de Moodle o la página de inicio.

## 6. Destrucción (Limpieza)
**MUY IMPORTANTE:** Cuando termines la prueba, borra todo para que no te cobren.
```bash
terraform destroy -auto-approve
```
*Verificación:* Asegúrate de que termine diciendo `Destroy complete!`.
