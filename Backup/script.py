import os
import zipfile

# Nombre de la carpeta limpia
project_dir = "TFG-FINAL-CORREGIDO"

# --- CONTENIDO DE LOS ARCHIVOS .TF (VERSIÓN FINAL ARREGLADA) ---
files = {
    "provider.tf": """terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
""",

    "variables.tf": """# --- variables.tf ---
variable "aws_region" {
  description = "Región de AWS"
  default     = "eu-south-2"
}

variable "project_name" {
  description = "Nombre base"
  default     = "tfg-bytemind"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

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

variable "instance_type" {
  default = "t3.micro"
}

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
""",

    "main.tf": """# --- main.tf ---
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = { Name = "${var.project_name}-public-subnet-a" }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_b
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"
  tags = { Name = "${var.project_name}-public-subnet-b" }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}a"
  tags = { Name = "${var.project_name}-private-subnet-a" }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_b_cidr
  availability_zone = "${var.aws_region}b"
  tags = { Name = "${var.project_name}-private-subnet-b" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}
""",

    "security.tf": """# --- security.tf ---
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "HTTP desde Internet"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-alb-sg" }
}

resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Trafico desde ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-web-sg" }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  tags = { Name = "${var.project_name}-rds-sg" }
}

resource "aws_security_group" "efs_sg" {
  name        = "${var.project_name}-efs-sg"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }
  tags = { Name = "${var.project_name}-efs-sg" }
}
""",

    "storage.tf": """# --- storage.tf ---
resource "aws_efs_file_system" "moodle_efs" {
  creation_token = "${var.project_name}-efs"
  encrypted      = true
  tags = { Name = "${var.project_name}-efs" }
}

resource "aws_efs_mount_target" "efs_mt_a" {
  file_system_id  = aws_efs_file_system.moodle_efs.id
  subnet_id       = aws_subnet.private_subnet_a.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_efs_mount_target" "efs_mt_b" {
  file_system_id  = aws_efs_file_system.moodle_efs.id
  subnet_id       = aws_subnet.private_subnet_b.id
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_db_subnet_group" "moodle_db_sg" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
  tags = { Name = "Moodle DB Subnet Group" }
}

resource "aws_db_instance" "moodle_db" {
  allocated_storage      = 20
  db_name                = var.db_name
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.moodle_db_sg.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  tags = { Name = "${var.project_name}-rds" }
}
""",

    "compute.tf": """# --- compute.tf ---
resource "aws_iam_role" "ec2_efs_role" {
  name = "${var.project_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "efs_attachment" {
  role       = aws_iam_role.ec2_efs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_efs_role.name
}
""",

    "alb.tf": """# --- alb.tf ---
resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

resource "aws_lb_target_group" "alb_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}
""",

    "asg.tf": """# --- asg.tf (CON EL ARREGLO DE RUTA) ---
resource "aws_launch_template" "moodle_lt" {
  name_prefix   = "${var.project_name}-lt-"
  # TU AMI ID (Si borraste la imagen, esto fallará. Si existe, funcionará)
  image_id      = "ami-0216c40e040e8230b" 
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # --- AQUÍ ESTABA EL ERROR: RUTA CORREGIDA ---
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # 1. Crear directorio correcto (fuera de html)
              mkdir -p /var/www/moodledata
              
              # 2. Montar EFS
              mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${aws_efs_file_system.moodle_efs.dns_name}:/ /var/www/moodledata
              
              # 3. Permisos
              chown -R www-data:www-data /var/www/moodledata
              chmod -R 770 /var/www/moodledata
              chown -R www-data:www-data /var/www/html/moodle
              
              systemctl restart apache2
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "${var.project_name}-asg-instance" }
  }
}

resource "aws_autoscaling_group" "moodle_asg" {
  name                = "${var.project_name}-asg"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  target_group_arns   = [aws_lb_target_group.alb_tg.arn]

  launch_template {
    id      = aws_launch_template.moodle_lt.id
    version = "$Latest"
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-node"
    propagate_at_launch = true
  }

  depends_on = [aws_efs_mount_target.efs_mt_a, aws_efs_mount_target.efs_mt_b]
}
""",

    "outputs.tf": """# --- outputs.tf ---
output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}
output "rds_endpoint" {
  value = aws_db_instance.moodle_db.address
}
"""
}

# Crear directorio
if not os.path.exists(project_dir):
    os.makedirs(project_dir)

# Escribir archivos
print(f"Creando archivos en {project_dir}...")
for filename, content in files.items():
    file_path = os.path.join(project_dir, filename)
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  - {filename} creado.")

# Crear ZIP
zip_filename = f"{project_dir}.zip"
print(f"Creando archivo ZIP: {zip_filename}...")
with zipfile.ZipFile(zip_filename, 'w') as zipf:
    for root, dirs, files_list in os.walk(project_dir):
        for file in files_list:
            zipf.write(os.path.join(root, file), file)

print("\n¡PROCESO COMPLETADO! Usa la carpeta TFG-FINAL-CORREGIDO")