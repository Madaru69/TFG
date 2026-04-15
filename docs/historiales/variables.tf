# --- variables.tf (VERSIÓN FINAL CON t3.micro) ---

# 1. Región de AWS
variable "aws_region" {
  description = "La region de AWS donde desplegaremos la infraestructura"
  type        = string
  default     = "eu-south-2" # España
}

# 2. Nombre del Proyecto (Para etiquetar recursos)
# Recuerda: En minúsculas para evitar errores de AWS
variable "project_name" {
  description = "Nombre base para los recursos del proyecto"
  type        = string
  default     = "tfg-bytemind"
}

# --- RED (VPC y Subredes) ---

variable "vpc_cidr" {
  description = "CIDR block para la VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}

# Subred Pública A (Zona A)
variable "public_subnet_cidr" {
  description = "CIDR para la primera subred publica (AZ a)"
  type        = string
  default     = "10.0.1.0/24"
}

# Subred Pública B (Zona B - Para Alta Disponibilidad)
variable "public_subnet_cidr_b" {
  description = "CIDR para la segunda subred publica (AZ b)"
  type        = string
  default     = "10.0.4.0/24"
}

# Subred Privada A (Datos Zona A)
variable "private_subnet_cidr" {
  description = "CIDR para la primera subred privada (AZ a)"
  type        = string
  default     = "10.0.2.0/24"
}

# Subred Privada B (Datos Zona B)
variable "private_subnet_b_cidr" {
  description = "CIDR para la segunda subred privada (AZ b)"
  type        = string
  default     = "10.0.3.0/24"
}

# --- BASE DE DATOS (RDS) ---

variable "db_name" {
  description = "Nombre de la base de datos inicial en RDS"
  type        = string
  default     = "moodle"
}

variable "db_username" {
  description = "Nombre del usuario maestro de la base de datos"
  type        = string
  default     = "adminmoodle"
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña del usuario maestro de la base de datos"
  type        = string
  # ¡IMPORTANTE! Para el TFG lo dejamos aquí.
  default     = "PasswordSeguro123!"
  sensitive   = true
}

# --- COMPUTACIÓN (EC2 / Auto Scaling) ---

# Variable necesaria para el archivo asg.tf
variable "instance_type" {
  description = "El tipo de instancia EC2 a usar para los servidores web del Auto Scaling"
  type        = string
  # [CAMBIO IMPORTANTE] Usamos t3.micro para mejor disponibilidad en la región de España
  default     = "t3.micro" 
}

# --- SEGURIDAD ---

variable "allowed_ssh_cidr" {
  description = "CIDR permitido para acceso SSH (Recomendado: IP de la Oficina/VPN)"
  type        = string
  # Por defecto abierto para el laboratorio, pero parametrizeado para producción
  default     = "0.0.0.0/0"
}

# --- IMAGENES (AMI) ---

variable "ami_id" {
  description = "ID de la Amazon Machine Image (AMI) para los servidores web"
  type        = string
  # Esta es la "Golden AMI" creada manualmente con la instalación de Moodle
  default     = "ami-0216c40e040e8230b"
}