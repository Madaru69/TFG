variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "eu-south-2" # España
}

variable "project_name" {
  description = "Nombre del proyecto (minúsculas)"
  type        = string
  default     = "tfg-bytemind"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# Subredes
variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}
variable "public_subnet_cidr_b" {
  default = "10.0.4.0/24"
}
variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}
variable "private_subnet_b_cidr" {
  default = "10.0.3.0/24"
}

# Computación
variable "instance_type" {
  default = "t3.micro"
}

# Base de Datos
variable "db_name" {
  default = "moodle"
}
variable "db_username" {
  default   = "adminmoodle"
  sensitive = true
}
variable "db_password" {
  default   = "PasswordSeguro123!"
  sensitive = true
}