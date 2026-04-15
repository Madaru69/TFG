# --- compute.tf ---

# 1. Buscar la última imagen de Ubuntu 22.04 automáticamente
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. Crear el Servidor Web (EC2) con la Receta de Instalación
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro" 
  key_name      = "tfg-key" 

  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # Necesitamos permiso para que el servidor pueda preguntarle a AWS por el ID del EFS
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # --- AQUI EMPIEZA LA MAGIA: El historial convertido en script ---
  user_data = <<-EOF
              #!/bin/bash
              # Activar modo "debug" para ver todo lo que pasa en el log del sistema
              set -x
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

              echo "--- INICIO DE INSTALACIÓN AUTOMÁTICA DE MOODLE ---"

              # 1. Actualizar e instalar dependencias (Incluimos 'awscli' para buscar el EFS)
              export DEBIAN_FRONTEND=noninteractive
              apt-get update
              apt-get upgrade -y
              apt-get install -y apache2 nfs-common git unzip mariadb-client awscli
              apt-get install -y php libapache2-mod-php php-cli php-mysql php-gd php-xml php-curl php-mbstring php-zip php-intl php-soap php-xmlrpc php-bcmath

              # 2. Descubrimiento y Montaje del EFS (El truco DevOps)
              echo "Buscando el ID del EFS..."
              # Usamos la CLI de AWS para encontrar el ID basado en el nombre del proyecto y la región
              EFS_ID=$(aws efs describe-file-systems --region ${var.aws_region} --query "FileSystems[?Name=='${var.project_name}-EFS'].FileSystemId" --output text)
              EFS_DNS="$${EFS_ID}.efs.${var.aws_region}.amazonaws.com"
              echo "EFS encontrado: $EFS_DNS"

              mkdir -p /var/www/moodledata
              
              # Añadir al fstab para persistencia en reinicios
              echo "$EFS_DNS:/ /var/www/moodledata nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
              
              # Montar todo lo que hay en fstab ahora mismo
              mount -a

              # Permisos de datos
              chown -R www-data:www-data /var/www/moodledata
              chmod -R 770 /var/www/moodledata

              # 3. Descargar Moodle
              cd /var/www/html
              rm index.html
              # Clonamos directamente en la carpeta actual (.) para no tener que mover archivos luego
              git clone -b MOODLE_403_STABLE git://git.moodle.org/moodle.git .
              
              # Permisos del código
              chown -R www-data:www-data /var/www/html
              chmod -R 755 /var/www/html

              # 4. Configuración de PHP (Método "fuerza bruta" que funcionó al final)
              PHP_INI="/etc/php/8.1/apache2/php.ini"
              echo "max_input_vars = 5000" >> $PHP_INI
              echo "memory_limit = 256M" >> $PHP_INI
              echo "max_execution_time = 60" >> $PHP_INI

              # 5. Reiniciar Apache para aplicar todo
              systemctl restart apache2

              echo "--- FIN DE INSTALACIÓN AUTOMÁTICA ---"
              EOF

  tags = {
    Name = "${var.project_name}-WebServer"
  }
}

# --- NECESARIO PARA LA AUTOMATIZACIÓN DEL EFS ---
# Creamos un "Permiso" (Rol IAM) para que la EC2 pueda ejecutar comandos "aws efs describe..."
resource "aws_iam_role" "ec2_efs_role" {
  name = "${var.project_name}-EC2-EFS-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Le damos permiso de solo lectura a EFS
resource "aws_iam_role_policy_attachment" "efs_ro_attach" {
  role       = aws_iam_role.ec2_efs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemReadOnlyAccess"
}

# Creamos el perfil de instancia para pegárselo a la EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-EC2-Profile"
  role = aws_iam_role.ec2_efs_role.name
}

# 3. Output para ver la IP al terminar
output "server_public_ip" {
  description = "IP Publica para acceder al servidor"
  value       = aws_instance.web_server.public_ip
}