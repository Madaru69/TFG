# --- alb.tf (Balanceo Dinámico de Carga) ---

# 1. Security Group del ALB: Punto de entrada público
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-ALB-SG"
  description = "Filtro de trafico HTTP entrante (Edge Security)"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Entrada universal para usuarios finales
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # Salida permitida para comunicación con los Backends
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ALB-SG"
  }
}

# 2. Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-ALB"
  internal           = false 
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  
  # Distribución estratégica en múltiples Zonas de Disponibilidad
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-ALB"
  }
}

# 3. Target Group: Pool de recursos para Moodle
resource "aws_lb_target_group" "alb_tg" {
  name     = "${var.project_name}-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  # Health Check (El ALB vigila que los servidores estén vivos)
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-TargetGroup"
  }
}

# 4. Listener (El "oído" del ALB)
# Escucha en el puerto 80 y manda el tráfico a la lista VIP (Target Group).
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

# --- [SECCIÓN ELIMINADA] ---
# Hemos borrado el recurso "aws_lb_target_group_attachment" que había aquí.
# Ahora el Auto Scaling Group (en asg.tf) se encarga de esta conexión automáticamente.

# OUTPUTS
output "alb_dns_name" {
  description = "El nombre DNS publico del Balanceador de Carga"
  value       = aws_lb.app_alb.dns_name
}