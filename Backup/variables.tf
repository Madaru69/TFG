variable "aws_region" {
  description = "Región de AWS donde desplegaremos"
  default     = "eu-south-2" 
}

variable "project_name" {
  description = "Nombre del proyecto para etiquetar recursos"
  default     = "Bytemind-TFG"
}

variable "vpc_cidr" {
  description = "Rango de IP VPC"
  default     = "10.0.0.0/16"
}