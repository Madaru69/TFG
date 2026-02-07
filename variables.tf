# --- variables.tf (VERSIÓN FINAL) ---

# 1. Región de AWS
variable "aws_region" {
  description = "La region de AWS donde desplegaremos la infraestructura"
  type        = string
  default     = "eu-south-2" # España
}

# 2. Nombre del Proyecto
variable "project_name" {
  description = "Nombre base para los recursos del proyecto"
  type        = string
  default     = "tfg-bytemind"
}

# --- RED ---
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Subred Pública A"
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_b" {
  description = "Subred Pública B (Alta Disponibilidad)"
  default     = "10.0.4.0/24"
}

variable "private_subnet_cidr" {
  description = "Subred Privada A"
  default     = "10.0.2.0/24"
}

variable "private_subnet_b_cidr" {
  description = "Subred Privada B"
  default     = "10.0.3.0/24"
}

# --- COMPUTACIÓN ---
variable "instance_type" {
  description = "Tipo de instancia (Escalado a t3.medium por falta de stock total en Madrid)"
  type        = string
  default     = "t3.medium"
}

# --- BASE DE DATOS ---
variable "db_name" {
  default = "moodle"
}

variable "db_username" {
  default   = "adminmoodle"
  sensitive = true
}

variable "db_password" {
  # ¡IMPORTANTE! Cambia esto o usa un archivo tfvars secreto
  default   = "PasswordSeguro123!"
  sensitive = true
}

# --- DOMINIO ---
variable "domain_name" {
  description = "Dominio principal del proyecto"
  type        = string
  default     = "bytemind.es"
}
