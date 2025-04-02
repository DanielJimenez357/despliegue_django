terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  shared_config_files      = ["/Users/Usuario/.aws/config"]
  shared_credentials_files = ["/Users/Usuario/.aws/credentials"]
}

resource "aws_instance" "web" {
  ami                         = var.ami
  instance_type               = var.instancia
  subnet_id                   = aws_subnet.subnetPublica.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.grupo_seguridad.id]
  key_name                    = "clave"
 
  user_data = <<-EOF
              #!/bin/bash
              echo "Starting deployment script" > /tmp/deploy.log
              whoami >> /tmp/deploy.log
              echo "Home directory: $HOME" >> /tmp/deploy.log
              
              apt-get update
              apt-get install -y python3-pip python3-dev git nginx python3-venv
              
              mkdir -p /opt/django_app
              cd /opt/django_app
              
              echo "Cloning repository..." >> /tmp/deploy.log
              git clone https://github.com/DanielJimenez357/despliegue_django .
              if [ $? -ne 0 ]; then
                echo "Git clone failed" >> /tmp/deploy.log
                exit 1
              fi
              
              echo "Repository contents:" >> /tmp/deploy.log
              find . -type f -name "*.py" | sort >> /tmp/deploy.log
              
              echo "Looking for manage.py..." >> /tmp/deploy.log
              DJANGO_DIR=$(find . -name manage.py -exec dirname {} \; | head -n 1)
              if [ -z "$DJANGO_DIR" ]; then
                echo "manage.py not found in repository" >> /tmp/deploy.log
                # Default to repository root if no manage.py found
                DJANGO_DIR="."
              fi
              
              echo "Django directory: $DJANGO_DIR" >> /tmp/deploy.log
              
              python3 -m venv /opt/django_venv
              source /opt/django_venv/bin/activate
              
              pip install --upgrade pip
              pip install django
              echo "Django installed version:" >> /tmp/deploy.log
              pip freeze | grep Django >> /tmp/deploy.log
              
              cd "$DJANGO_DIR"
              if [ -f "requirements.txt" ]; then
                pip install -r requirements.txt
                echo "Installed requirements from requirements.txt" >> /tmp/deploy.log
              fi
              
              if [ -f "manage.py" ]; then
                echo "Found manage.py, preparing Django service" >> /tmp/deploy.log
                python manage.py check >> /tmp/deploy.log 2>&1
                python manage.py migrate >> /tmp/deploy.log 2>&1
                
                cat > /etc/systemd/system/django.service <<EOL
[Unit]
Description=Django Application Service
After=network.target

[Service]
User=root
Group=root
WorkingDirectory=/opt/django_app/$DJANGO_DIR
ExecStart=/opt/django_venv/bin/python manage.py runserver 0.0.0.0:80
Restart=always

[Install]
WantedBy=multi-user.target
EOL
                
                chmod 644 /etc/systemd/system/django.service
                systemctl daemon-reload
                systemctl enable django
                systemctl start django
                echo "Django service status:" >> /tmp/deploy.log
                systemctl status django >> /tmp/deploy.log 2>&1
              else
                echo "manage.py not found, cannot start Django service" >> /tmp/deploy.log
              fi
              EOF
  
  tags = {
    Name = "django-server"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

resource "aws_security_group" "grupo_seguridad" {
  name        = "grupo_seguridad"
  description = "grupo_seguridad"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "grupo_seguridad"
  }
}


