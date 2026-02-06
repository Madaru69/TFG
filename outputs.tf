output "moodle_url" {
  description = "Enlace directo para acceder a Moodle"
  value       = "http://${aws_lb.app_alb.dns_name}"
}

output "efs_id" {
  description = "ID del Sistema de Archivos EFS para referencia"
  value       = aws_efs_file_system.moodle_efs.id
}

output "alb_tg_arn" {
  description = "ARN del Target Group para verificar salud de las instancias"
  value       = aws_lb_target_group.alb_tg.arn
}
