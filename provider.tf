terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Estrategia de Etiquetado para FinOps (Control de Costes)
  # Estas etiquetas se heredan automáticamente en todos los recursos
  default_tags {
    tags = {
      Proyecto    = "TFG-Bytemind-IaC"
      Entorno     = "Laboratorio"
      Propietario = "David Arbelaez"
      Gestion     = "Terraform"
    }
  }
}
